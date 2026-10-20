import '../data/offline_translations.dart';
import '../data/offline_translations_extra.dart';
import '../data/offline_translations_library.dart';
import '../models/vocabulary_item.dart';
import 'vocabulary_catalog.dart';

class BoardVocabulary {
  static final _translations = {
    ...OfflineTranslations.data,
    ...ExtraTranslations.data,
    ...LibraryTranslations.data,
  };

  static String label(String english, String languageCode) =>
      _translations['$languageCode||$english'] ?? english;

  /// Prefer the fixed core item when the same label occurs in several places.
  static List<VocabularyItem> get items => VocabularyCatalog.items;
}
