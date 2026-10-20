import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/emergency_phrases.dart';
import '../../models/echo_language.dart';
import '../../models/prepared_board.dart';
import '../../services/app_settings.dart';
import '../../services/board_vocabulary.dart';
import '../../services/language_scope.dart';
import '../../services/speech_service.dart';
import '../../services/tense_converter.dart';
import '../../widgets/tense_selector.dart';
import '../../widgets/vocabulary_grid.dart';
import 'board_dialogs.dart';

class BoardPresentScreen extends StatefulWidget {
  final PreparedBoard board;
  const BoardPresentScreen({super.key, required this.board});
  @override
  State<BoardPresentScreen> createState() => _BoardPresentScreenState();
}

class _BoardPresentScreenState extends State<BoardPresentScreen> {
  final SpeechService _speech = SpeechService();
  final List<String> _words = [];
  SentenceTense _tense = SentenceTense.present;
  bool _tenseSelected = false;
  String get _message => _tenseSelected
      ? TenseConverter.convert(_words.join(' '), _tense, _language.code).text
      : _words.join(' ');

  void _changeTense(SentenceTense tense) => setState(() {
    _tense = tense;
    _tenseSelected = true;
  });

  void _clearMessage() => setState(() {
    _words.clear();
    _tense = SentenceTense.present;
    _tenseSelected = false;
  });
  final FocusNode _switchFocus = FocusNode();
  final ScrollController _contentScroll = ScrollController();
  late EchoLanguage _language = AppSettings.language.value;
  int _section = 0;
  bool _speaking = false;
  int _speechRequest = 0;
  Timer? _scanTimer;
  int _scan = 0;
  final Map<int, GlobalKey> _scanTargets = {};
  GlobalKey _targetKey(int index) =>
      _scanTargets.putIfAbsent(index, () => GlobalKey());

  BoardSection? get _current =>
      widget.board.sections.isEmpty ? null : widget.board.sections[_section];

  @override
  void initState() {
    super.initState();
    AppSettings.switchScanningEnabled.addListener(_configureScanning);
    _configureScanning();
  }

  void _configureScanning() {
    _scanTimer?.cancel();
    _scan = 0;
    if (AppSettings.switchScanningEnabled.value) {
      _scanTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          setState(() => _scan = (_scan + 1) % _scanActions.length);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final target = _scanTargets[_scan]?.currentContext;
            if (mounted && target != null) {
              Scrollable.ensureVisible(
                target,
                alignment: 0.35,
                duration: const Duration(milliseconds: 200),
              );
            }
          });
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _switchFocus.requestFocus();
      });
    }
    if (mounted) setState(() {});
  }

  List<VoidCallback> get _scanActions => [
    for (final item in _current?.items ?? [])
      () => setState(
        () => _words.add(BoardVocabulary.label(item.label, _language.code)),
      ),
    () {
      if (_words.isNotEmpty && !_speaking) _speak(_message, _language);
    },
    _stop,
    () {
      if (_words.isNotEmpty) setState(() => _words.removeLast());
    },
    _clearMessage,
    () {
      if (_section > 0) _navigate(-1);
    },
    () {
      if (_section < widget.board.sections.length - 1) _navigate(1);
    },
    _emergency,
    for (final tense in SentenceTense.values)
      () {
        if (TenseConverter.supportsLanguage(_language.code)) {
          _changeTense(tense);
        }
      },
  ];

  bool _highlight(int action) =>
      AppSettings.switchScanningEnabled.value && _scan == action;

  @override
  void dispose() {
    AppSettings.switchScanningEnabled.removeListener(_configureScanning);
    _scanTimer?.cancel();
    _switchFocus.dispose();
    _contentScroll.dispose();
    unawaited(_speech.dispose());
    super.dispose();
  }

  Future<void> _stop() async {
    _speechRequest++;
    if (mounted) setState(() => _speaking = false);
    await _speech.stop();
  }

  Future<void> _speak(String text, EchoLanguage language) async {
    final request = ++_speechRequest;
    setState(() => _speaking = true);
    final success = await _speech.speak(text, language);
    if (!mounted || request != _speechRequest) return;
    setState(() => _speaking = false);
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('boards_voice_error'))));
    }
  }

  void _navigate(int direction) {
    unawaited(_stop());
    setState(() {
      _section += direction;
      _scan = 0;
    });
    if (_contentScroll.hasClients) _contentScroll.jumpTo(0);
  }

  Future<void> _languageChanged(EchoLanguage? language) async {
    if (language == null || language == _language) return;
    if (_words.isNotEmpty &&
        !await boardConfirm(
          context,
          context.tr('boards_change_language'),
          context.tr('boards_change_language_message'),
          context.tr('clear'),
        )) {
      return;
    }
    if (!mounted) return;
    await _stop();
    if (mounted) {
      setState(() {
        _language = language;
        _words.clear();
        _tense = SentenceTense.present;
        _tenseSelected = false;
      });
    }
  }

  Future<void> _emergency() async {
    await _stop();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.7,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.tr('emergency_title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final phrase in EmergencyPhrases.all)
                ListTile(
                  leading: const Icon(Icons.volume_up),
                  title: Text(phrase.inLanguage(_language) ?? phrase.english),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _speak(
                      phrase.inLanguage(_language) ?? phrase.english,
                      phrase.inLanguage(_language) == null
                          ? EchoLanguage.english
                          : _language,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (mounted && AppSettings.switchScanningEnabled.value) {
      _switchFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final section = _current;
    final actionStart = section?.items.length ?? 0;
    return Focus(
      focusNode: _switchFocus,
      autofocus: AppSettings.switchScanningEnabled.value,
      onKeyEvent: (_, event) {
        if (AppSettings.switchScanningEnabled.value &&
            event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          final actions = _scanActions;
          actions[_scan % actions.length]();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.board.title),
          actions: [
            IconButton(
              tooltip: context.tr('emergency_title'),
              icon: const Icon(Icons.emergency_outlined),
              onPressed: _emergency,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<EchoLanguage>(
                  isExpanded: true,
                  value: _language,
                  onChanged: _languageChanged,
                  items: EchoLanguage.all
                      .map(
                        (l) => DropdownMenuItem(value: l, child: Text(l.label)),
                      )
                      .toList(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _contentScroll,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        section?.title ?? context.tr('boards_no_sections'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (section != null)
                        Text(
                          '${_section + 1} / ${widget.board.sections.length}',
                        ),
                      const SizedBox(height: 12),
                      if (section != null && section.items.isEmpty)
                        Text(context.tr('boards_no_words')),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: section?.items.length ?? 0,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 180,
                              mainAxisExtent: 150,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemBuilder: (context, index) {
                          final item = section!.items[index];
                          final label = BoardVocabulary.label(
                            item.label,
                            _language.code,
                          );
                          return Semantics(
                            key: _targetKey(index),
                            button: true,
                            child: VocabularyTile(
                              item: item,
                              label: label,
                              secondaryLabel: _language.isEnglish
                                  ? null
                                  : item.label,
                              isHighlighted: _highlight(index),
                              onTap: () => setState(() => _words.add(label)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _words.isEmpty
                                ? context.tr('boards_sentence_hint')
                                : _message,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TenseSelector(
                        value: _tense,
                        source: _words.join(' '),
                        conversionRequested: _tenseSelected,
                        languageCode: _language.code,
                        onChanged: _changeTense,
                      ),
                      if (AppSettings.switchScanningEnabled.value)
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final tense in SentenceTense.values)
                              _control(
                                context.tr('tense_${tense.name}'),
                                Icons.schedule,
                                TenseConverter.supportsLanguage(_language.code)
                                    ? () => _changeTense(tense)
                                    : null,
                                actionStart + 7 + tense.index,
                              ),
                          ],
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _control(
                            context.tr('speak'),
                            Icons.volume_up,
                            _words.isEmpty || _speaking
                                ? null
                                : () => _speak(_message, _language),
                            actionStart,
                          ),
                          _control(
                            context.tr('boards_stop'),
                            Icons.stop,
                            _stop,
                            actionStart + 1,
                          ),
                          _control(
                            context.tr('delete'),
                            Icons.backspace_outlined,
                            _words.isEmpty
                                ? null
                                : () => setState(() => _words.removeLast()),
                            actionStart + 2,
                          ),
                          _control(
                            context.tr('clear'),
                            Icons.clear,
                            _words.isEmpty ? null : _clearMessage,
                            actionStart + 3,
                          ),
                          _control(
                            context.tr('emergency_title'),
                            Icons.emergency_outlined,
                            _emergency,
                            actionStart + 6,
                          ),
                        ],
                      ),
                      if (AppSettings.switchScanningEnabled.value)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(context.tr('boards_scan_hint')),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: _control(
                        context.tr('boards_previous'),
                        Icons.chevron_left,
                        _section > 0 ? () => _navigate(-1) : null,
                        actionStart + 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _control(
                        context.tr('boards_next'),
                        Icons.chevron_right,
                        _section < widget.board.sections.length - 1
                            ? () => _navigate(1)
                            : null,
                        actionStart + 5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _control(
    String label,
    IconData icon,
    VoidCallback? action,
    int scanIndex,
  ) => OutlinedButton.icon(
    key: _targetKey(scanIndex),
    onPressed: action,
    icon: Icon(icon),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      backgroundColor: _highlight(scanIndex) ? Colors.amber.shade200 : null,
      side: _highlight(scanIndex)
          ? const BorderSide(color: Colors.orange, width: 3)
          : null,
    ),
  );
}
