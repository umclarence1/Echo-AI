import 'package:flutter/material.dart';
import '../../models/practice.dart';
import '../../services/practice_repository.dart';
import '../../services/practice_run.dart';
import '../boards/board_dialogs.dart';
import 'practice_session_screen.dart';
import 'practice_summary.dart';

class PracticeScreen extends StatefulWidget {
  final PracticeRepository? repository;
  const PracticeScreen({super.key, this.repository});
  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PracticeRepository _repository =
      widget.repository ?? PracticeRepository();
  PracticeData? _data;
  bool _busy = false;
  String? _error;
  int _seconds = 60;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _repository.load();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not read practice data. Your saved data has not been changed.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _change(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      final data = await _repository.load();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save. Please retry; learner names must be different.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addLearner() async {
    final name = await boardNameDialog(context, 'Add learner');
    if (name == null || !mounted) return;
    await _change(
      () =>
          _repository.addProfile(PracticeProfile(id: practiceId(), name: name)),
    );
  }

  Future<void> _start() async {
    final data = _data;
    if (data == null || _busy || _error != null) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PracticeSessionScreen(
          profile: data.selectedProfile,
          plannedSeconds: _seconds,
          repository: _repository,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _clear() async {
    final profile = _data!.selectedProfile;
    if (await boardConfirm(
          context,
          'Clear practice history?',
          'Remove all practice results for ${profile.name} from this device? Other learners and saved boards will be kept.',
          'Clear history',
        ) &&
        mounted) {
      await _change(() => _repository.clearHistory(profile.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final history =
        data == null
              ? <PracticeResult>[]
              : data.results
                    .where((r) => r.profileId == data.selectedProfileId)
                    .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final timed = history
        .where(
          (r) =>
              r.completed &&
              r.plannedSeconds == _seconds &&
              r.deckVersion == PracticePrompts.version,
        )
        .toList();
    final best = timed.isEmpty
        ? null
        : timed
              .map((r) => r.sentencesPerMinute)
              .reduce((a, b) => a > b ? a : b);
    final delta = timed.length < 2
        ? null
        : timed[0].sentencesPerMinute - timed[1].sentencesPerMinute;
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Build more sentences',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Read the prompt, navigate the board and choose pictograms in the same order. Tap Check to count a match and get the next prompt. Correct mistakes with Delete or Clear, or use Skip.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'English prompts · common everyday sentences · no AI. The timer starts when the board is ready and keeps running in menus and in the background.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('practice_profile_${data.selectedProfileId}'),
                  initialValue: data.selectedProfileId,
                  decoration: const InputDecoration(labelText: 'Learner'),
                  items: [
                    for (final p in data.profiles)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: _busy
                      ? null
                      : (id) {
                          if (id != null) {
                            _change(() => _repository.selectProfile(id));
                          }
                        },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _busy ? null : _addLearner,
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Add learner'),
                  ),
                ),
                DropdownButtonFormField<int>(
                  initialValue: _seconds,
                  decoration: const InputDecoration(
                    labelText: 'Session length',
                  ),
                  items: [
                    for (final seconds in [60, 120, 300])
                      DropdownMenuItem(
                        value: seconds,
                        child: Text(
                          '${seconds ~/ 60} ${seconds == 60 ? 'minute' : 'minutes'}',
                        ),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) {
                          if (v != null) setState(() => _seconds = v);
                        },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start practice'),
                ),
                const SizedBox(height: 24),
                Text(
                  '${data.selectedProfile.name}’s progress',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${history.length} saved sessions · ${history.fold<int>(0, (sum, r) => sum + r.sentences)} matched sentences'
                  ' · ${practiceTime(history.fold<int>(0, (sum, r) => sum + r.elapsedMs))} total practice',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal best · ${_seconds ~/ 60}-minute timed sessions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          best == null
                              ? 'Complete a full timed session to set a personal best.'
                              : '${best.toStringAsFixed(1)} sentences per minute',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (timed.isNotEmpty)
                          Text(
                            'Latest: ${timed.first.sentencesPerMinute.toStringAsFixed(1)} SPM',
                          ),
                        if (delta != null)
                          Text(
                            '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} SPM compared with the previous ${_seconds ~/ 60}-minute run',
                          ),
                        const Text(
                          'Comparisons use the same duration and prompt set. Early-ended sessions are excluded.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Session history',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No sessions yet. Your results will appear here after practice.',
                    ),
                  ),
                for (final result in history)
                  Card(
                    child: ExpansionTile(
                      title: Text(
                        '${result.sentencesPerMinute.toStringAsFixed(1)} SPM · ${result.sentences} matched',
                      ),
                      subtitle: Text(
                        '${practiceDate(result.startedAt)} · ${result.completed ? 'Timed' : 'Ended early'} · ${practiceTime(result.elapsedMs)}',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: PracticeResultSummary(result: result),
                        ),
                      ],
                    ),
                  ),
                if (history.isNotEmpty)
                  TextButton(
                    onPressed: _busy ? null : _clear,
                    child: const Text('Clear this learner’s history'),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Learners, responses and results are saved only on this device/browser. They are not linked to an online account or synced. Clearing browser/site data removes them. Finish or end a session to save it; closing the app during practice can lose the active session.',
                ),
              ],
            ),
    );
  }
}
