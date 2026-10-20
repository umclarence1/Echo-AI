import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/practice.dart';
import '../models/vocabulary_item.dart';
import '../data/library_vocabulary.dart';
import '../data/collections_data.dart';
import 'board_vocabulary.dart';
import 'pictogram_assets.dart';

class PracticePrompt {
  final String id;
  final List<String> words;
  PracticePrompt(this.id, List<String> words)
    : words = List.unmodifiable(words);
  String get text {
    final sentence = words.join(' ').toLowerCase();
    return '${sentence[0].toUpperCase()}${sentence.substring(1)}.';
  }

  bool matches(String answer) =>
      normalize(answer) == normalize(words.join(' '));
  static String normalize(String text) => text
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'[.!?]+$'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

class PracticePrompts {
  static const version = 'english-varied-v2';
  static List<PracticePrompt> build({Iterable<VocabularyItem>? vocabulary}) {
    final labels = (vocabulary ?? BoardVocabulary.items)
        .map((i) => i.label)
        .where((label) => PictogramAssets.localAssetFor(label) != null)
        .toSet();
    // Categories supply the actual words. Grammar tags restrict combinations
    // where English would need an unavailable article (e.g. "I want a book").
    final foodWords = {
      for (final c in LibraryVocabulary.categories)
        if (c.id == 'food_drink') ...c.words.map((w) => w.label),
      for (final c in CollectionsData.getCollections())
        if (c.id == 'collection_food') ...c.items.map((w) => w.label),
      if (labels.contains('Food')) 'Food',
    }.intersection(labels);
    const massOrPluralFood = {
      'Food',
      'Water',
      'Rice',
      'Bread',
      'Fruit',
      'Soup',
      'Fufu',
      'Banku',
      'Kenkey',
      'Jollof Rice',
      'Waakye',
      'Kelewele',
      'Grapes',
      'Beans',
      'Yam',
      'Cassava',
      'Chicken',
      'Fish',
      'Meat',
      'Beef',
      'Pork',
      'Butter',
      'Cheese',
      'Milk',
      'Yogurt',
      'Ice cream',
      'Cake',
      'Chocolate',
      'Candy',
      'Sugar',
      'Salt',
      'Oil',
      'Flour',
      'Honey',
      'Jam',
      'Salad',
      'Pizza',
      'Chips',
      'Noodles',
      'Pasta',
      'Tea',
      'Coffee',
      'Juice',
      'Soda',
      'Breakfast',
      'Lunch',
      'Dinner',
      'Shrimp',
      'Crab meat',
      'Garlic',
      'Ginger',
      'Lettuce',
      'Spinach',
      'Okra',
      'Peas',
      'Popcorn',
      'Toast',
      'Cereal',
      'Broccoli',
      'Cauliflower',
      'Beetroot',
      'Celery',
      'Eggplant',
    };
    final food = foodWords.intersection(massOrPluralFood);
    final drinks = food.intersection({
      'Water',
      'Milk',
      'Tea',
      'Coffee',
      'Juice',
      'Soda',
    });
    final edible = food.difference(drinks).difference({'Oil', 'Flour'});
    final pluralThings =
        {
          for (final c in LibraryVocabulary.categories)
            if (c.id == 'clothes' || c.id == 'home_things')
              ...c.words.map((w) => w.label),
        }.intersection(labels).intersection({
          'Trousers',
          'Shoes',
          'Socks',
          'Gloves',
          'Boots',
          'Sandals',
          'Shorts',
          'Jeans',
          'Sunglasses',
          'Pajamas',
          'Pyjamas',
          'Crayons',
          'Scissors',
        });
    final objects = {
      ...food,
      ...pluralThings,
      ...labels.intersection({'Help', 'Medicine', 'Rest'}),
    };
    final actions = labels.intersection({
      'Walk',
      'Run',
      'Jump',
      'Sit',
      'Stand',
      'Swim',
      'Read',
      'Write',
      'Work',
      'Play',
      'Sleep',
      'Sing',
      'Dance',
      'Pray',
      'Rest',
    });
    final prompts = <String, PracticePrompt>{};
    void add(List<String> words) {
      // Check every slot, including the subject, verb, modifier and object.
      if (!words.every(labels.contains)) return;
      final id = words.join('/');
      prompts.putIfAbsent(id, () => PracticePrompt(id, words));
    }

    for (final subject in ['I', 'You']) {
      for (final verb in ['Want', 'Need']) {
        for (final object in objects) {
          add([subject, verb, object]);
          add([subject, verb, object, 'Please']);
          add([subject, verb, 'More', object]);
        }
      }
      for (final object in edible) {
        add([subject, 'Eat', object]);
      }
      for (final object in drinks) {
        add([subject, 'Drink', object]);
      }
      for (final object in {...food, ...pluralThings}) {
        add([subject, 'Like', object]);
      }
      for (final action in actions) {
        add([subject, action]);
      }
      for (final place in ['Home', 'Outside']) {
        add([subject, 'Go', place]);
      }
    }
    for (final action in {...actions, 'Help', 'Stop', 'Wait', 'Eat', 'Drink'}) {
      add(['Please', action]);
    }
    for (final object in edible) {
      add(['Please', 'Eat', object]);
    }
    for (final object in drinks) {
      add(['Please', 'Drink', object]);
    }
    return prompts.values.toList();
  }
}

/// Deadline checks happen on every action, independently of timer callbacks.
/// Stopwatch time keeps counting while a library, dialog or background tab is open.
class PracticeRun extends ChangeNotifier {
  final PracticeProfile profile;
  final int plannedSeconds;
  final Random _random;
  final List<PracticePrompt> _deck;
  final Stopwatch _watch = Stopwatch();
  final Duration Function()? _testElapsed;
  final DateTime Function() _now;
  final String id = practiceId();
  final List<PracticeResponse> _responses = [];
  late DateTime _startedAt;
  int _index = 0;
  int revision = 0;
  int _lastRemaining = -1;
  bool started = false;
  PracticeResult? _result;
  String answer = '';
  String feedback = '';

  PracticeRun({
    required this.profile,
    required this.plannedSeconds,
    Random? random,
    List<PracticePrompt>? prompts,
    Duration Function()? elapsed,
    DateTime Function()? now,
  }) : _random = random ?? Random(),
       _deck = List.of(prompts ?? PracticePrompts.build()),
       _testElapsed = elapsed,
       _now = now ?? DateTime.now {
    if (plannedSeconds <= 0 || _deck.isEmpty) {
      throw ArgumentError('Invalid practice session');
    }
    _deck.shuffle(_random);
  }
  PracticePrompt get prompt => _deck[_index];
  bool get finished => _result != null;
  PracticeResult? get result => _result;
  int get elapsedMs => !started
      ? 0
      : finished
      ? _result!.elapsedMs
      : (_testElapsed?.call() ?? _watch.elapsed).inMilliseconds.clamp(
          0,
          plannedSeconds * 1000,
        );
  int get remainingSeconds =>
      ((plannedSeconds * 1000 - elapsedMs) / 1000).ceil();
  int get sentences =>
      _responses.where((r) => r.outcome == PracticeOutcome.correct).length;
  double get liveSpm => elapsedMs == 0 ? 0 : sentences * 60000 / elapsedMs;

  void start() {
    if (started) return;
    started = true;
    _startedAt = _now();
    _watch.start();
    notifyListeners();
  }

  void tick() {
    if (!started || finished) return;
    if (elapsedMs >= plannedSeconds * 1000) {
      _finish(true);
    } else if (_lastRemaining != remainingSeconds) {
      _lastRemaining = remainingSeconds;
      notifyListeners();
    }
  }

  bool get acceptsInput {
    tick();
    return started && !finished;
  }

  void setAnswer(String value) {
    if (started && !finished) answer = value;
  }

  void check() {
    final at = _actionTime();
    if (at == null) return;
    if (answer.trim().isEmpty) {
      feedback = 'Choose pictograms to build the sentence first.';
      notifyListeners();
      return;
    }
    final correct = prompt.matches(answer);
    _record(correct ? PracticeOutcome.correct : PracticeOutcome.incorrect, at);
    if (correct) {
      _next();
      feedback = 'Matched! Build the next sentence.';
    } else {
      feedback =
          'Keep trying. Match the words and their order, then tap Check.';
    }
    notifyListeners();
  }

  void skip() {
    final at = _actionTime();
    if (at == null) return;
    _record(PracticeOutcome.skipped, at);
    _next();
    feedback = 'Skipped. Try this sentence.';
    notifyListeners();
  }

  int? _actionTime() {
    if (!started || finished) return null;
    final at = elapsedMs;
    if (at >= plannedSeconds * 1000) {
      _finish(true);
      return null;
    }
    return at;
  }

  void _record(PracticeOutcome outcome, int at) => _responses.add(
    PracticeResponse(
      promptId: prompt.id,
      target: prompt.text,
      answer: answer,
      outcome: outcome,
      elapsedMs: at,
    ),
  );
  void _next() {
    final previous = prompt.id;
    _index++;
    if (_index == _deck.length) {
      _index = 0;
      _deck.shuffle(_random);
      if (_deck.length > 1 && _deck.first.id == previous) {
        final first = _deck.removeAt(0);
        _deck.add(first);
      }
    }
    answer = '';
    revision++;
  }

  void end() {
    if (!started || finished) return;
    _finish(elapsedMs >= plannedSeconds * 1000);
  }

  void _finish(bool completed) {
    final duration = completed
        ? plannedSeconds * 1000
        : elapsedMs.clamp(1, plannedSeconds * 1000);
    _watch.stop();
    _result = PracticeResult(
      id: id,
      profileId: profile.id,
      startedAt: _startedAt,
      plannedSeconds: plannedSeconds,
      elapsedMs: duration,
      completed: completed,
      deckVersion: PracticePrompts.version,
      responses: _responses,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _watch.stop();
    super.dispose();
  }
}
