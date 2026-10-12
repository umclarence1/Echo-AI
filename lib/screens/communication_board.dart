import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vocabulary_item.dart';
import '../models/context.dart';
import '../models/collection.dart';
import '../models/echo_language.dart';
import '../data/core_vocabulary.dart';
import '../data/context_data.dart';
import '../data/collections_data.dart';
import '../data/emergency_phrases.dart';
import '../data/gender_forms.dart';
import '../data/offline_translations.dart';
import '../data/offline_translations_extra.dart';
import '../data/offline_translations_library.dart';
import '../widgets/sentence_builder.dart';
import '../widgets/vocabulary_grid.dart';
import '../widgets/action_buttons.dart';
import '../services/pictogram_loader.dart';
import '../services/khaya_service.dart';
import '../services/arasaac_service.dart';
import '../services/app_settings.dart';
import '../services/speech_cache.dart';
import '../services/device_voice.dart';
import '../services/language_scope.dart';
import '../services/natural_speech.dart';
import '../services/user_data_store.dart';
import 'favorites_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'voice_profile_screen.dart';

class CommunicationBoard extends StatefulWidget {
  const CommunicationBoard({super.key});

  @override
  State<CommunicationBoard> createState() => _CommunicationBoardState();
}

class _CommunicationBoardState extends State<CommunicationBoard> {
  final TextEditingController _textController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _switchFocusNode = FocusNode();

  Timer? _scanTimer;
  int _scanIndex = 0;

  List<VocabularyItem> sentence = [];
  // The text each tapped word resolved to at the moment it was tapped, kept
  // in step with `sentence`. This is what actually renders - each word
  // keeps whatever language was active when it was added, which is what
  // makes code-switching (mixing languages mid-sentence) work.
  List<String> sentenceDisplayWords = [];
  List<VocabularyItem> coreVocabulary = CoreVocabulary.getItems();
  List<Context> contexts = ContextData.getContexts();
  List<Collection> collections = CollectionsData.getCollections();
  // Home is shown from the start rather than leaving the board mostly empty
  // below the core row - people can still switch or close it.
  late Context? selectedContext = contexts.isNotEmpty ? contexts.first : null;

  // Saved on the device (UserDataStore) so they survive closing the app.
  List<VocabularyItem> people = UserDataStore.loadPeople();
  List<VocabularyItem> favorites = UserDataStore.loadFavorites();
  final Map<String, int> _usageCounts = UserDataStore.loadUsage();
  final List<Context> _savedCustomContexts = UserDataStore.loadCustomContexts();

  bool isLoadingPictograms = true;
  bool isSearching = false;
  List<String> speechSuggestions = [];

  bool isTranslating = false;
  bool isSpeaking = false;
  // Cache key: "langCode||English label" -> translated label. Pre-seeded
  // with the bundled offline set so known vocabulary never needs a live
  // call; only ad hoc words (search) fall through to the network.
  final Map<String, String> _translations = {
    ...OfflineTranslations.data,
    ...ExtraTranslations.data,
    ...LibraryTranslations.data,
  };

  EchoLanguage get selectedLanguage => AppSettings.language.value;

  @override
  void initState() {
    super.initState();
    _loadPictograms();
    _textController.addListener(_updateSpeechSuggestions);
    AppSettings.naturalSpeechEnabled.addListener(_updateSpeechSuggestions);
    AppSettings.speakerGender.addListener(_onGrammarChanged);
    AppSettings.language.addListener(_onLanguageNotified);
    AppSettings.switchScanningEnabled.addListener(_onScanningToggled);
    if (AppSettings.switchScanningEnabled.value) _startScanning();
    if (!selectedLanguage.isEnglish) {
      _ensureTranslationsLoaded(selectedLanguage);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_updateSpeechSuggestions);
    AppSettings.naturalSpeechEnabled.removeListener(_updateSpeechSuggestions);
    AppSettings.speakerGender.removeListener(_onGrammarChanged);
    AppSettings.language.removeListener(_onLanguageNotified);
    AppSettings.switchScanningEnabled.removeListener(_onScanningToggled);
    _scanTimer?.cancel();
    _switchFocusNode.dispose();
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onScanningToggled() {
    if (AppSettings.switchScanningEnabled.value) {
      _startScanning();
    } else {
      _scanTimer?.cancel();
      setState(() => _scanIndex = 0);
    }
  }

  void _startScanning() {
    _scanTimer?.cancel();
    setState(() => _scanIndex = 0);
    _scanTimer = Timer.periodic(
      Duration(milliseconds: AppSettings.scanIntervalMs.value),
      (_) {
        if (coreVocabulary.isEmpty) return;
        setState(() => _scanIndex = (_scanIndex + 1) % coreVocabulary.length);
      },
    );
  }

  VocabularyItem? get _highlightedItem {
    if (!AppSettings.switchScanningEnabled.value || coreVocabulary.isEmpty) {
      return null;
    }
    return coreVocabulary[_scanIndex % coreVocabulary.length];
  }

  void _activateHighlighted() {
    final item = _highlightedItem;
    if (item != null) addToSentence(item);
  }

  Future<void> _loadPictograms() async {
    final updatedCoreVocab = await PictogramLoader.loadPictogramsForList(
      coreVocabulary,
    );

    final List<Context> updatedContexts = [];
    for (final context in contexts) {
      final updatedVocab = await PictogramLoader.loadPictogramsForList(
        context.vocabulary,
      );
      updatedContexts.add(
        Context(
          id: context.id,
          label: context.label,
          symbolUrl: context.symbolUrl,
          vocabulary: updatedVocab,
        ),
      );
    }

    final List<Collection> updatedCollections = [];
    for (final collection in collections) {
      final updatedItems = await PictogramLoader.loadPictogramsForList(
        collection.items,
      );
      updatedCollections.add(
        Collection(
          id: collection.id,
          label: collection.label,
          symbolUrl: collection.symbolUrl,
          items: updatedItems,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      coreVocabulary = updatedCoreVocab;
      // The person's own contexts are added after the built-in ones. Their
      // pictograms were saved when they were created, so nothing is fetched
      // here and starting the app stays instant even with no internet.
      contexts = [...updatedContexts, ..._savedCustomContexts];
      collections = updatedCollections;
      isLoadingPictograms = false;
    });
  }

  static final _connectorFeel = VocabularyItem(
    id: 'connector_feel',
    label: 'feel',
    symbolUrl: ArasaacService.getPictogramUrl('3293'),
  );

  List<VocabularyItem> get _allVocabularyItems => [
    ...coreVocabulary,
    for (final context in contexts) ...context.vocabulary,
    for (final collection in collections) ...collection.items,
    ...people,
    ...favorites,
    _connectorFeel,
  ];

  /// Every word that can appear in Frequently Used, including the library.
  List<VocabularyItem> get _lookupItems => [
    ..._allVocabularyItems,
    ...LibraryScreen.allItems,
  ];

  /// The text shown on a tile. Feeling words follow the speaker's grammar
  /// (cansado or cansada) in French.
  String _displayLabel(VocabularyItem item) {
    if (item.collectionId == 'collection_feel' &&
        AppSettings.speakerIsFeminine) {
      final feminine =
          GenderForms.feminineAdjective['${selectedLanguage.code}||${item.label}'];
      if (feminine != null) return feminine;
    }
    return _nameLabel(item.label);
  }

  /// Translates any English word or name (tile, context or collection)
  /// into the selected language, falling back to English when there is no
  /// translation yet.
  String _nameLabel(String english) {
    if (selectedLanguage.isEnglish) return english;
    return _translations['${selectedLanguage.code}||$english'] ?? english;
  }

  // Shows the English original under a translated tile, so the board still
  // reads for anyone in a mixed-language household - null (no subtitle)
  // when English is already the primary label.
  String? _englishSubtitle(VocabularyItem item) {
    if (selectedLanguage.isEnglish) return null;
    return item.label;
  }

  /// Called from the language menu; everything else follows through
  /// AppSettings.language.
  void _onLanguageChanged(EchoLanguage? language) {
    if (language == null) return;
    AppSettings.language.value = language;
  }

  void _onLanguageNotified() {
    if (!mounted) return;
    // Start the message fresh in the new language, rather than leaving the
    // old sentence sitting in the box - simpler to follow, especially when
    // demonstrating one language at a time.
    clearSentence();
    if (!selectedLanguage.isEnglish) {
      _ensureTranslationsLoaded(selectedLanguage);
    }
  }

  void _onGrammarChanged() {
    if (!mounted) return;
    setState(() {});
    _updateSpeechSuggestions();
  }

  Future<void> _ensureTranslationsLoaded(EchoLanguage language) async {
    // French is fully bundled; only Khaya languages need a call.
    final khayaCode = language.khayaCode;
    if (khayaCode == null) return;

    final missingLabels = _allVocabularyItems
        // People's names stay as they are.
        .where((item) => item.collectionId != 'collection_people')
        .map((item) => item.label)
        .toSet()
        .where(
          (label) => !_translations.containsKey('${language.code}||$label'),
        )
        .toList();

    if (missingLabels.isEmpty) return;

    setState(() => isTranslating = true);
    try {
      final results = await Future.wait(
        missingLabels.map(
          (label) => KhayaService.translateFromEnglish(label, khayaCode),
        ),
      );
      for (var i = 0; i < missingLabels.length; i++) {
        final translated = results[i];
        if (translated != null) {
          _translations['${language.code}||${missingLabels[i]}'] = translated;
        }
      }
    } finally {
      if (mounted) setState(() => isTranslating = false);
    }
  }

  void _countUse(VocabularyItem item) {
    _usageCounts[item.id] = (_usageCounts[item.id] ?? 0) + 1;
    unawaited(UserDataStore.saveUsage(_usageCounts));
  }

  void addToSentence(VocabularyItem item) {
    setState(() {
      sentence.add(item);
      sentenceDisplayWords.add(_displayLabel(item));
      _textController.text = _buildSentenceText();
      _countUse(item);
    });
  }

  /// Feel collection items merge with a preceding "I" instead of just
  /// appending, so "I" + "Happy" reads as "I feel happy" (or "Me siento
  /// feliz") rather than the two words stacked side by side.
  void _addFeelSelection(VocabularyItem item) {
    setState(() {
      final lastWasI =
          sentence.isNotEmpty && sentence.last.label.toLowerCase() == 'i';
      final prefix = selectedLanguage.feelPrefix;
      if (lastWasI && prefix != null) {
        // The language has its own grammar for feelings: "Yo" + "Feliz"
        // becomes "Me siento feliz", not the word-by-word "Yo siento Feliz".
        sentenceDisplayWords[sentenceDisplayWords.length - 1] = prefix;
        sentence.add(item);
        sentenceDisplayWords.add(_displayLabel(item).toLowerCase());
      } else {
        if (lastWasI) {
          sentence.add(_connectorFeel);
          sentenceDisplayWords.add(_displayLabel(_connectorFeel));
        }
        sentence.add(item);
        sentenceDisplayWords.add(_displayLabel(item));
      }
      _countUse(item);
      _textController.text = _buildSentenceText();
    });
  }

  /// Routes a Frequently Used tap through the right insertion logic - a
  /// Feel word still needs the "I" + feeling merge grammar even when it's
  /// surfaced outside the Feel collection itself.
  void _activateFrequentlyUsed(VocabularyItem item) {
    if (item.collectionId == 'collection_feel') {
      _addFeelSelection(item);
    } else {
      addToSentence(item);
    }
  }

  /// Up to 6 most-tapped words across the whole board, most-used first.
  /// Separate from the fixed core grid so core vocabulary positions never
  /// change - this is purely an additional shortcut.
  List<VocabularyItem> get _frequentlyUsedItems {
    if (_usageCounts.isEmpty) return [];
    final itemsById = {for (final item in _lookupItems) item.id: item};
    final rankedIds = _usageCounts.keys.toList()
      ..sort((a, b) => _usageCounts[b]!.compareTo(_usageCounts[a]!));
    return rankedIds
        .map((id) => itemsById[id])
        .whereType<VocabularyItem>()
        .take(6)
        .toList();
  }

  void deleteLastWord() {
    setState(() {
      if (sentence.isNotEmpty) {
        sentence.removeLast();
        sentenceDisplayWords.removeLast();
        _textController.text = _buildSentenceText();
      }
    });
  }

  void clearSentence() {
    setState(() {
      sentence.clear();
      sentenceDisplayWords.clear();
      _textController.clear();
      speechSuggestions = [];
    });
  }

  Future<void> speakSentence() =>
      _speak(_textController.text.trim(), selectedLanguage);

  /// Speaks [text] in [language]: Khaya first for Khaya languages (cached
  /// after the first time), the phone's own voice for French and as
  /// the English fallback. A missing voice never blocks communication - the
  /// message is already built and visible.
  Future<void> _speak(String text, EchoLanguage language) async {
    if (text.isEmpty || isSpeaking) return;

    setState(() => isSpeaking = true);
    // Silence whichever voice engine spoke last - the phone's TTS and the
    // Khaya audio player are two separate systems, so switching languages
    // between taps never overlaps or plays out of order.
    await _audioPlayer.stop();
    await DeviceVoice.stop();
    try {
      // Languages Khaya doesn't cover (French) use the phone's own
      // voice - free, offline, no quota.
      if (!language.prefersKhayaVoice) {
        final spoke =
            language.voiceLocale != null &&
            await DeviceVoice.speak(text, language.voiceLocale!);
        if (!spoke && mounted) {
          _showMessage(context.tr('no_voice', {'lang': language.label}));
        }
        return;
      }

      var audio = await SpeechCache.read(text, language.code);
      final fromCache = audio != null;
      audio ??= await KhayaService.synthesizeSpeech(text, language.khayaCode!);

      if (audio != null) {
        if (!fromCache) {
          // Don't block playback on the write - cache it for next time.
          unawaited(SpeechCache.write(text, language.code, audio));
        }
        await _audioPlayer.play(BytesSource(audio));
        return;
      }

      // Khaya is unreachable: use the phone's voice if it has one for this
      // language (English), otherwise the message stays on screen.
      final spoke =
          language.voiceLocale != null &&
          await DeviceVoice.speak(text, language.voiceLocale!);
      if (!spoke && mounted) _showMessage(context.tr('no_connection'));
    } finally {
      if (mounted) setState(() => isSpeaking = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void selectContext(Context context) {
    setState(() => selectedContext = context);
  }

  // ------------------------------------------------------------ emergency

  void _openEmergency() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    context.tr('emergency_title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final phrase in EmergencyPhrases.all)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red.shade900,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _sayEmergency(phrase);
                            },
                            child: Text(
                              phrase.inLanguage(selectedLanguage) ??
                                  phrase.english,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows and speaks an emergency phrase at once. Where a language has no
  /// translation yet (Twi, Ga) the English phrase is spoken instead, so an
  /// emergency is never left silent.
  void _sayEmergency(EmergencyPhrase phrase) {
    final translated = phrase.inLanguage(selectedLanguage);
    final text = translated ?? phrase.english;
    setState(() {
      sentence.clear();
      sentenceDisplayWords.clear();
      _textController.text = text;
    });
    _speak(text, translated != null ? selectedLanguage : EchoLanguage.english);
  }

  // -------------------------------------------------------------- library

  void _openLibrary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryScreen(
          items: LibraryScreen.allItems,
          categoryName: _nameLabel,
          labelBuilder: _displayLabel,
          secondaryLabelBuilder: _englishSubtitle,
          onItemTap: addToSentence,
        ),
      ),
    );
  }

  // ---------------------------------------------------------- collections

  void _openCollection(Collection collection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.5,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _nameLabel(collection.label),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: VocabularyGrid(
                    items: collection.items,
                    labelBuilder: _displayLabel,
                    secondaryLabelBuilder: _englishSubtitle,
                    onItemTap: (item) {
                      Navigator.pop(sheetContext);
                      if (collection.id == 'collection_feel') {
                        _addFeelSelection(item);
                      } else {
                        addToSentence(item);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPeopleCollection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.6,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _nameLabel('People'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await _showAddPersonDialog();
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: Text(context.tr('add_person')),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: people.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  context.tr('no_people'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : VocabularyGrid(
                              items: people,
                              labelBuilder: _displayLabel,
                              secondaryLabelBuilder: _englishSubtitle,
                              onItemTap: (item) {
                                Navigator.pop(sheetContext);
                                addToSentence(item);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddPersonDialog() {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    String category = 'Family';
    const categories = {
      'Family': 'family',
      'Friends': 'friends',
      'Professionals': 'professionals',
    };

    return showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(context.tr('add_person')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: context.tr('display_name'),
                    ),
                    autofocus: true,
                  ),
                  TextField(
                    controller: relationshipController,
                    decoration: InputDecoration(
                      labelText: context.tr('relationship_optional'),
                      hintText: context.tr('relationship_hint'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(
                      labelText: context.tr('category'),
                    ),
                    items: categories.entries
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.key,
                            child: Text(context.tr(c.value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => category = value ?? category),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(context.tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final relationship = relationshipController.text.trim();
                    setState(() {
                      people.add(
                        VocabularyItem(
                          id: 'person_${DateTime.now().millisecondsSinceEpoch}',
                          label: name,
                          collectionId: 'collection_people',
                          relationship: relationship.isEmpty
                              ? null
                              : relationship,
                        ),
                      );
                    });
                    unawaited(UserDataStore.savePeople(people));
                    Navigator.pop(dialogContext);
                  },
                  child: Text(context.tr('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------- search

  Future<void> _searchAndAddWord() async {
    final controller = TextEditingController();
    final term = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('find_word')),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: context.tr('find_word_hint')),
            onSubmitted: (value) => Navigator.pop(dialogContext, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(context.tr('search')),
            ),
          ],
        );
      },
    );

    final query = term?.trim();
    if (query == null || query.isEmpty) return;

    setState(() => isSearching = true);
    try {
      final ids = await ArasaacService.searchPictograms(query);
      final item = VocabularyItem(
        id: 'search_${DateTime.now().millisecondsSinceEpoch}',
        label: query,
        symbolUrl: ids.isNotEmpty
            ? ArasaacService.getPictogramUrl(ids.first)
            : null,
      );
      if (!mounted) return;
      addToSentence(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('added_word', {'w': query})),
          action: SnackBarAction(
            label: context.tr('save_favorite'),
            onPressed: () {
              setState(() => favorites.add(item));
              unawaited(UserDataStore.saveFavorites(favorites));
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isSearching = false);
    }
  }

  // ------------------------------------------------------------- contexts

  bool _isCustom(Context c) => c.id.startsWith('custom_');

  void _saveCustomContexts() {
    unawaited(
      UserDataStore.saveCustomContexts(contexts.where(_isCustom).toList()),
    );
  }

  void _openContextPicker() {
    Navigator.of(context).pop(); // close drawer
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ...contexts.map((ctx) {
                return ListTile(
                  title: Text(_nameLabel(ctx.label)),
                  selected: ctx.id == selectedContext?.id,
                  trailing: _isCustom(ctx)
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              contexts = contexts
                                  .where((c) => c.id != ctx.id)
                                  .toList();
                              if (selectedContext?.id == ctx.id) {
                                selectedContext = null;
                              }
                            });
                            _saveCustomContexts();
                            Navigator.pop(sheetContext);
                          },
                        )
                      : null,
                  onTap: () {
                    selectContext(ctx);
                    Navigator.pop(sheetContext);
                  },
                );
              }),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: Text(context.tr('create_context')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _createContextDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Lets a person make their own context (say, "Grandma's house") from a
  /// list of words. It is saved on the device and comes back next time.
  Future<void> _createContextDialog() async {
    final nameController = TextEditingController();
    final wordsController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('create_context')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.tr('context_name'),
                  hintText: context.tr('context_name_hint'),
                ),
              ),
              TextField(
                controller: wordsController,
                decoration: InputDecoration(
                  labelText: context.tr('context_words'),
                  hintText: context.tr('context_words_hint'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.tr('create')),
            ),
          ],
        );
      },
    );
    if (created != true) return;

    final name = nameController.text.trim();
    final words = wordsController.text
        .split(',')
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toSet()
        .take(24)
        .toList();
    if (name.isEmpty || words.isEmpty) return;

    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final context0 = Context(
      id: id,
      label: name,
      vocabulary: [
        for (var i = 0; i < words.length; i++)
          VocabularyItem(id: '${id}_$i', label: words[i], contexts: [id]),
      ],
    );
    setState(() {
      contexts = [...contexts, context0];
      selectedContext = context0;
    });
    _saveCustomContexts();
    unawaited(_findPictogramsFor(id));
  }

  /// Looks up pictograms for a new context's words in the background (needs
  /// internet the first time) and saves them so they work offline afterwards.
  Future<void> _findPictogramsFor(String contextId) async {
    final index = contexts.indexWhere((c) => c.id == contextId);
    if (index < 0) return;
    final original = contexts[index];

    final resolved = <VocabularyItem>[];
    for (final item in original.vocabulary) {
      resolved.add(await PictogramLoader.loadPictogramForWord(item));
      if (!mounted) return;
    }

    setState(() {
      contexts = [
        for (final c in contexts)
          c.id == contextId
              ? Context(
                  id: c.id,
                  label: c.label,
                  symbolUrl: c.symbolUrl,
                  vocabulary: resolved,
                )
              : c,
      ];
      if (selectedContext?.id == contextId) {
        selectedContext = contexts.firstWhere((c) => c.id == contextId);
      }
    });
    _saveCustomContexts();
  }

  // ------------------------------------------------------ natural speech

  String _buildSentenceText() {
    return sentenceDisplayWords.join(' ');
  }

  void _updateSpeechSuggestions() {
    if (!mounted) return;
    final suggestions = AppSettings.naturalSpeechEnabled.value
        ? NaturalSpeech.suggest(
            language: selectedLanguage,
            rawText: _textController.text,
            items: sentence,
            word: _nameLabel,
            feminine: AppSettings.speakerIsFeminine,
          )
        : <String>[];
    if (listEquals(suggestions, speechSuggestions)) return;
    setState(() => speechSuggestions = suggestions);
  }

  void _applySuggestion(String suggestion) {
    setState(() {
      _textController.text = suggestion;
      speechSuggestions = [];
    });
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.switchScanningEnabled,
      builder: (context, scanningEnabled, _) {
        return KeyboardListener(
          focusNode: _switchFocusNode,
          autofocus: scanningEnabled,
          onKeyEvent: (event) {
            if (!scanningEnabled) return;
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.space ||
                    event.logicalKey == LogicalKeyboardKey.enter)) {
              _activateHighlighted();
            }
          },
          child: Scaffold(
            key: _scaffoldKey,
            drawer: _buildDrawer(),
            floatingActionButton: scanningEnabled
                ? FloatingActionButton.extended(
                    onPressed: _activateHighlighted,
                    icon: const Icon(Icons.check_circle),
                    label: Text(context.tr('select')),
                  )
                : null,
            body: SafeArea(
              child: isLoadingPictograms
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(context.tr('loading')),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildTopBar(),

                        // Fixed-height reservation, not a conditional insert,
                        // so tiles below never shift position when this
                        // appears - motor-planning consistency matters for
                        // AAC users.
                        SizedBox(
                          height: 2,
                          child: isTranslating
                              ? const LinearProgressIndicator(minHeight: 2)
                              : null,
                        ),

                        _buildCollectionsRow(),

                        if (_frequentlyUsedItems.isNotEmpty)
                          _buildFrequentlyUsedRow(),

                        SentenceBuilder(
                          controller: _textController,
                          onDelete: deleteLastWord,
                          onClear: clearSentence,
                          speechSuggestions: speechSuggestions,
                          onApplySuggestion: _applySuggestion,
                        ),

                        // Core vocabulary stays at the top of this area and never
                        // moves; the chosen context sits below it. On a small
                        // screen the area scrolls instead of overflowing.
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                VocabularyGrid(
                                  items: coreVocabulary,
                                  onItemTap: addToSentence,
                                  labelBuilder: _displayLabel,
                                  secondaryLabelBuilder: _englishSubtitle,
                                  highlightedItem: _highlightedItem,
                                ),
                                if (selectedContext != null)
                                  VocabularyGrid(
                                    items: selectedContext!.vocabulary,
                                    onItemTap: addToSentence,
                                    labelBuilder: _displayLabel,
                                    secondaryLabelBuilder: _englishSubtitle,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        ActionButtons(
                          onSpeak: speakSentence,
                          onDelete: deleteLastWord,
                          onClear: clearSentence,
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text('Echo', style: TextStyle(fontSize: 28)),
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(context.tr('menu_contexts')),
              onTap: _openContextPicker,
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(context.tr('menu_favorites')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FavoritesScreen(
                      items: favorites,
                      labelBuilder: _displayLabel,
                      onItemTap: addToSentence,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic_outlined),
              title: Text(context.tr('menu_voice')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VoiceProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(context.tr('menu_settings')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(context.tr('menu_about')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionsRow() {
    // Emergency and the word library are pinned at the left so they are
    // always one tap away; the collections scroll beside them.
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Flexible + ellipsis: these two shrink rather than overflow on
          // a narrow screen or with a large system font.
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade800,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: _openEmergency,
                icon: const Icon(Icons.warning_amber_rounded, size: 16),
                label: Text(
                  context.tr('emergency'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: _openLibrary,
                icon: const Icon(Icons.grid_view, size: 16),
                label: Text(
                  context.tr('library_short'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...collections.map((collection) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () => _openCollection(collection),
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: Text(_nameLabel(collection.label)),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _openPeopleCollection,
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: Text(_nameLabel('People')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequentlyUsedRow() {
    // Built from individual tiles in a horizontal strip, not VocabularyGrid
    // (which lays out a multi-row grid) - this is a single scrollable row.
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Text(
              context.tr('frequently_used'),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _frequentlyUsedItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: SizedBox(
                    width: 64,
                    child: VocabularyTile(
                      item: item,
                      label: _displayLabel(item),
                      secondaryLabel: _englishSubtitle(item),
                      onTap: () => _activateFrequentlyUsed(item),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    // Two rows so the bar fits a phone held upright: the title, search and
    // language on top, the message box and context below.
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
      color: Colors.blue.shade100,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const Text(
                'Echo',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                tooltip: context.tr('find_word_tooltip'),
                icon: isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                onPressed: isSearching ? null : _searchAndAddWord,
              ),
              SizedBox(
                width: 112,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<EchoLanguage>(
                    isDense: true,
                    isExpanded: true,
                    value: selectedLanguage,
                    // The closed box shows just the name; "draft" appears in
                    // the open list, where there is room.
                    selectedItemBuilder: (_) => EchoLanguage.all
                        .map(
                          (l) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(l.label, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    items: EchoLanguage.all.map((language) {
                      return DropdownMenuItem<EchoLanguage>(
                        value: language,
                        child: Text(
                          language.isDraft
                              ? '${language.label} (draft)'
                              : language.label,
                        ),
                      );
                    }).toList(),
                    onChanged: _onLanguageChanged,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: context.tr('type_message'),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 128,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Context>(
                      isDense: true,
                      isExpanded: true,
                      hint: Text(
                        context.tr('select_context'),
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: selectedContext,
                      items: contexts.map((Context ctx) {
                        return DropdownMenuItem<Context>(
                          value: ctx,
                          child: Text(
                            _nameLabel(ctx.label),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (Context? newContext) {
                        if (newContext != null) {
                          selectContext(newContext);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
