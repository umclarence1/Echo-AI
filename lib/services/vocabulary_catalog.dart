import '../data/core_vocabulary.dart';
import '../data/context_data.dart';
import '../data/collections_data.dart';
import '../data/library_vocabulary.dart';
import '../models/collection.dart';
import '../models/context.dart';
import '../models/vocabulary_item.dart';
import 'arasaac_service.dart';

class VocabularyCategory {
  final String id;
  final String label;
  final List<VocabularyItem> items;
  VocabularyCategory(this.id, this.label, Iterable<VocabularyItem> items)
    : items = List.unmodifiable(items);
}

/// One complete index for Words, collections, contexts and prepared boards.
/// The generated library is an extension list, not an exhaustive vocabulary.
class VocabularyCatalog {
  static const _contextGroups = {
    'context_home': 'home_things',
    'context_hospital': 'body_health',
    'context_school': 'school_fun',
    'context_restaurant': 'food_drink',
    'context_church': 'faith_culture',
    'context_market': 'money_market',
    'context_travel': 'getting_around',
  };
  static String _key(String label) => label.trim().toLowerCase();
  static final feelConnector = VocabularyItem(
    id: 'connector_feel',
    label: 'feel',
    symbolUrl: ArasaacService.getPictogramUrl('3293'),
  );
  static final _data = _build();
  static List<VocabularyItem> get items => _data.items;
  static List<VocabularyCategory> get categories => _data.categories;
  static List<VocabularyItem> categoryItems(String id) =>
      categories.firstWhere((c) => c.id == id).items;
  static bool belongsTo(VocabularyItem item, String id) {
    if (id == 'personal') {
      return !_data.memberships.containsKey(_key(item.label));
    }
    if (id == 'people' &&
        (item.collectionId == 'collection_people' ||
            item.id.startsWith('person_'))) {
      return true;
    }
    return _data.memberships[_key(item.label)]?.contains(id) ??
        item.collectionId == id;
  }

  static List<VocabularyItem> merge(Iterable<VocabularyItem> values) {
    final byLabel = <String, VocabularyItem>{};
    for (final item in values) {
      byLabel.putIfAbsent(_key(item.label), () => item);
    }
    return byLabel.values.toList();
  }

  static bool isFeelingState(String label) => {
    'happy',
    'sad',
    'angry',
    'scared',
    'excited',
    'tired',
    'sick',
    'confused',
    'worried',
    'nervous',
    'proud',
    'shy',
    'bored',
    'jealous',
    'surprised',
    'calm',
    'frustrated',
    'hungry',
    'thirsty',
    'loved',
    'embarrassed',
    'cheerful',
    'comfortable',
    'brave',
  }.contains(_key(label));

  static _CatalogData _build() {
    final core = CoreVocabulary.getItems();
    final seeds = CollectionsData.getCollections();
    final contexts = ContextData.getContexts();
    final byLabel = <String, VocabularyItem>{};
    final memberships = <String, Set<String>>{};
    void add(VocabularyItem item, Iterable<String> groups) {
      final key = _key(item.label);
      byLabel.putIfAbsent(key, () => item);
      memberships.putIfAbsent(key, () => {}).addAll(groups);
    }

    for (final item in core) {
      add(item, ['core']);
    }
    for (final category in LibraryVocabulary.categories) {
      for (final word in category.words) {
        add(
          VocabularyItem(
            id: 'lib_${word.label}',
            label: word.label,
            collectionId: category.id,
          ),
          [category.id],
        );
      }
    }
    // Built-in tiles were deliberately omitted by the library generator.
    // Map them by meaning rather than treating their source context as a category.
    const builtInGroups = <String, List<String>>{
      'Want': ['actions'],
      'Need': ['actions'],
      'Help': ['actions', 'body_health'],
      'Go': ['actions'],
      'Stop': ['actions'],
      'Please': ['social'],
      'Thank You': ['social'],
      'Yes': ['social'],
      'No': ['social'],
      'Bed': ['home_things'],
      'Bathroom': ['places'],
      'Kitchen': ['places'],
      'TV': ['home_things', 'technology'],
      'Phone': ['home_things', 'technology'],
      'Food': ['food_drink'],
      'Doctor': ['people', 'body_health'],
      'Nurse': ['people', 'body_health'],
      'Medicine': ['body_health'],
      'Pain': ['body_health'],
      'Rest': ['body_health', 'actions'],
      'Water': ['food_drink'],
      'Teacher': ['people', 'school_fun'],
      'Book': ['home_things', 'school_fun'],
      'Pencil': ['home_things', 'school_fun'],
      'Computer': ['home_things', 'school_fun', 'technology'],
      'Friend': ['people', 'social'],
      'Play': ['actions', 'school_fun'],
      'Menu': ['food_drink'],
      'Check': ['food_drink', 'money_market'],
      'Waiter': ['people', 'food_drink'],
      'Table': ['home_things', 'food_drink'],
      'Pastor': ['people', 'faith_culture'],
      'Bible': ['faith_culture'],
      'Pray': ['actions', 'faith_culture'],
      'Sing': ['actions', 'faith_culture'],
      'Offering': ['faith_culture', 'money_market'],
      'Amen': ['faith_culture', 'social'],
      'Money': ['money_market'],
      'Buy': ['actions', 'money_market'],
      'Sell': ['actions', 'money_market'],
      'Price': ['money_market'],
      'Bag': ['home_things', 'clothes', 'money_market'],
      'Seller': ['people', 'money_market'],
      'Car': ['getting_around'],
      'Bus': ['getting_around'],
      'Ticket': ['getting_around'],
      'Luggage': ['getting_around'],
      'Airport': ['places', 'getting_around'],
      'Trotro': ['getting_around'],
      'Station': ['places', 'getting_around'],
    };
    for (final context in contexts) {
      for (final item in context.vocabulary) {
        add(item, builtInGroups[item.label] ?? [_contextGroups[context.id]!]);
      }
    }
    const collectionGroups = {
      'collection_feel': 'feelings',
      'collection_food': 'food_drink',
      'collection_places': 'places',
    };
    for (final collection in seeds) {
      for (final item in collection.items) {
        add(item, [collectionGroups[collection.id]!]);
      }
    }
    for (final item in core) {
      add(item, builtInGroups[item.label] ?? []);
    }
    add(feelConnector, ['actions']);
    // Words can have several useful memberships without duplicate tiles in All Words.
    const crossGroups = <String, List<String>>{
      'Sick': ['body_health'],
      'Cry': ['actions'],
      'Laugh': ['actions'],
      'Smile': ['actions'],
      'Jeans': ['clothes'],
      'Sunglasses': ['clothes'],
      'Vest': ['clothes'],
      'School': ['school_fun'],
      'Church': ['faith_culture'],
      'Hospital': ['body_health'],
      'Market': ['money_market'],
      'Home': ['home_things'],
      'Pen': ['school_fun'],
      'Paper': ['school_fun'],
      'Scissors': ['school_fun'],
      'Glue': ['school_fun'],
      'Ruler': ['school_fun'],
      'Eraser': ['school_fun'],
      'Notebook': ['school_fun'],
      'Backpack': ['school_fun'],
      'Blackboard': ['school_fun'],
      'Desk': ['school_fun'],
      'Crayons': ['school_fun'],
      'Laptop': ['technology'],
      'Tablet': ['technology'],
      'Camera': ['technology'],
      'Headphones': ['technology'],
      'Radio': ['technology'],
      'Battery': ['technology'],
      'Spoon': ['home_things'],
      'Fork': ['home_things'],
      'Knife': ['home_things'],
      'Plate': ['home_things'],
      'Bowl': ['home_things'],
      'Cup': ['home_things'],
      'Glass': ['home_things'],
      'Bottle': ['home_things'],
      'Pot': ['home_things'],
      'Pan': ['home_things'],
    };
    for (final entry in crossGroups.entries) {
      final key = _key(entry.key);
      if (byLabel.containsKey(key)) memberships[key]!.addAll(entry.value);
    }
    for (final entry in memberships.entries) {
      if (entry.value.isEmpty) {
        throw StateError('Missing category for ${byLabel[entry.key]!.label}');
      }
    }
    final all = [
      for (final entry in byLabel.entries)
        entry.value.copyWith(
          collectionId: isFeelingState(entry.value.label)
              ? 'collection_feel'
              : entry.value.collectionId ?? memberships[entry.key]!.first,
        ),
    ];
    final groups = [
      VocabularyCategory(
        'core',
        'Core',
        all.where((i) => memberships[_key(i.label)]!.contains('core')),
      ),
      for (final category in LibraryVocabulary.categories)
        VocabularyCategory(
          category.id,
          category.label,
          all.where((i) => memberships[_key(i.label)]!.contains(category.id)),
        ),
    ];
    return _CatalogData(
      List.unmodifiable(all),
      List.unmodifiable(groups),
      memberships,
    );
  }

  /// Keep the original quick words first, then include the rest of that category.
  static List<Collection> get collections {
    final seeds = CollectionsData.getCollections();
    const ids = {
      'feelings': 'collection_feel',
      'food_drink': 'collection_food',
      'places': 'collection_places',
    };
    final ordered = [
      for (final id in ['feelings', 'food_drink', 'places'])
        categories.firstWhere((c) => c.id == id),
      ...categories.where(
        (c) => !{
          'feelings',
          'food_drink',
          'places',
          'people',
          'core',
        }.contains(c.id),
      ),
    ];
    return [
      for (final category in ordered)
        Collection(
          id: ids[category.id] ?? 'collection_${category.id}',
          label: category.id == 'feelings'
              ? 'Feel'
              : category.id == 'food_drink'
              ? 'Food'
              : category.label,
          items: merge([
            for (final seed in seeds)
              if (seed.id == ids[category.id]) ...seed.items,
            ...category.items,
          ]),
        ),
    ];
  }

  static List<Context> get contexts {
    return [
      for (final context in ContextData.getContexts())
        Context(
          id: context.id,
          label: context.label,
          symbolUrl: context.symbolUrl,
          vocabulary: merge([
            ...context.vocabulary,
            ...categoryItems(_contextGroups[context.id]!),
          ]),
        ),
    ];
  }
}

class _CatalogData {
  final List<VocabularyItem> items;
  final List<VocabularyCategory> categories;
  final Map<String, Set<String>> memberships;
  _CatalogData(this.items, this.categories, this.memberships);
}
