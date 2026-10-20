import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/echo_language.dart';
import '../../models/practice.dart';
import '../../services/language_scope.dart';
import '../../services/practice_repository.dart';
import '../../services/practice_run.dart';
import '../boards/board_dialogs.dart';
import '../communication_board.dart';
import 'practice_summary.dart';

class PracticeSessionScreen extends StatefulWidget {
  final PracticeProfile profile;
  final int plannedSeconds;
  final PracticeRepository repository;
  final PracticeRun? run;
  const PracticeSessionScreen({
    super.key,
    required this.profile,
    required this.plannedSeconds,
    required this.repository,
    this.run,
  });
  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen>
    with WidgetsBindingObserver {
  late final PracticeRun _run =
      widget.run ??
      PracticeRun(
        profile: widget.profile,
        plannedSeconds: widget.plannedSeconds,
      );
  final _language = ValueNotifier(EchoLanguage.english);
  Timer? _timer;
  bool _saved = false;
  bool _saving = false;
  bool _saveFailed = false;
  bool _allowLeave = false;
  bool _exitDialog = false;
  ModalRoute<dynamic>? _route;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _run.addListener(_changed);
    _timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _run.tick(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _run.tick();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    if (_run.finished && !_saving && !_saved && !_saveFailed) {
      _timer?.cancel();
      // Bring the result into view even if time expired in the word library.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _route != null) {
          Navigator.of(context).popUntil((r) => r == _route);
        }
      });
      unawaited(_save());
    }
  }

  Future<void> _save() async {
    if (_saving || _run.result == null) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await widget.repository.saveResult(_run.result!);
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _leave() async {
    if (_exitDialog || _saving) return;
    if (!_run.started || (_run.finished && _saved)) {
      setState(() => _allowLeave = true);
      Navigator.pop(context);
      return;
    }
    _exitDialog = true;
    final discard = _run.finished;
    final accepted = await boardConfirm(
      context,
      discard ? 'Leave without saving?' : 'End practice now?',
      discard
          ? 'This result could not be saved. Leaving now will lose it.'
          : 'Your result will be saved as an ended early session. The timer keeps running while this dialog is open.',
      discard ? 'Leave' : 'End session',
    );
    _exitDialog = false;
    if (!mounted || !accepted) return;
    if (discard) {
      setState(() => _allowLeave = true);
      Navigator.pop(context);
    } else {
      _run.end();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _run.removeListener(_changed);
    _run.dispose();
    _language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LanguageScope(
    language: _language,
    child: PopScope(
      canPop: _allowLeave || (_run.finished && _saved),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _run.finished
                ? 'Practice result'
                : 'Practice · ${widget.profile.name}',
          ),
          actions: [
            if (!_run.finished)
              TextButton(onPressed: _leave, child: const Text('End session')),
          ],
        ),
        body: _run.finished
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    _run.result!.completed ? 'Time’s up!' : 'Session ended',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  PracticeResultSummary(result: _run.result!),
                  const SizedBox(height: 16),
                  if (_saving) const Text('Saving result…'),
                  if (_saved)
                    const Text(
                      'Saved to this learner’s history on this device.',
                    ),
                  if (_saveFailed) ...[
                    const Text(
                      'Could not save. Your result is still open. Retry before leaving.',
                    ),
                    FilledButton(
                      onPressed: _save,
                      child: const Text('Retry saving'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saved ? _leave : null,
                    child: const Text('Back to practice'),
                  ),
                ],
              )
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          child: SizedBox(
                            height: constraints.maxHeight < 620
                                ? 620
                                : constraints.maxHeight,
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  color: Colors.blue.shade50,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 16,
                                        children: [
                                          Text(
                                            _run.started
                                                ? '${practiceTime(_run.remainingSeconds * 1000)} left'
                                                : 'Getting the board ready…',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text('${_run.sentences} matched'),
                                          Text(
                                            '${_run.liveSpm.toStringAsFixed(1)} live SPM',
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _run.prompt.text,
                                        key: const ValueKey('practice_prompt'),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      const Text(
                                        'Build this sentence with pictograms, then tap Check.',
                                      ),
                                      if (_run.feedback.isNotEmpty)
                                        Semantics(
                                          liveRegion: true,
                                          child: Text(_run.feedback),
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: CommunicationBoard(practice: _run),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _run.started ? _run.skip : null,
                              icon: const Icon(Icons.skip_next),
                              label: const Text('Skip'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _run.started ? _run.check : null,
                              icon: const Icon(Icons.check),
                              label: const Text('Check'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ),
  );
}
