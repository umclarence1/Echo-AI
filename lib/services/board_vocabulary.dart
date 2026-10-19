import '../data/core_vocabulary.dart';
import '../data/context_data.dart';
import '../data/collections_data.dart';
import '../data/library_vocabulary.dart';
import '../data/offline_translations.dart';
import '../data/offline_translations_extra.dart';
import '../data/offline_translations_library.dart';
import '../models/vocabulary_item.dart';

class BoardVocabulary {
  static final _translations = {
    ...OfflineTranslations.data,
    ...ExtraTranslations.data,
    ...LibraryTranslations.data,
  };

  static String label(String english, String languageCode) =>
      _translations['$languageCode||$english'] ?? english;

  /// Prefer the fixed core item when the same label occurs in several places.
  static final List<VocabularyItem> items = _build();
  static List<VocabularyItem> _build() {
    final byLabel = <String, VocabularyItem>{};
    final all = [
      ...CoreVocabulary.getItems(),
      for (final category in LibraryVocabulary.categories)
        for (final word in category.words)
          VocabularyItem(
            id: 'lib_${word.label}',
            label: word.label,
            collectionId: category.id,
          ),
      for (final c in ContextData.getContexts()) ...c.vocabulary,
      for (final c in CollectionsData.getCollections()) ...c.items,
    ];
    for (final item in all) {
      byLabel.putIfAbsent(item.label.toLowerCase(), () => item);
    }
    return byLabel.values.toList();
  }
}
