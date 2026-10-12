import '../services/arasaac_service.dart';
import '../services/pictogram_assets.dart';
import '../models/vocabulary_item.dart';

class PictogramLoader {
  /// Search for pictogram ID for a word and update the vocabulary item
  static Future<VocabularyItem> loadPictogramForWord(
    VocabularyItem item,
  ) async {
    if (item.symbolUrl != null && item.symbolUrl!.isNotEmpty) {
      return item;
    }
    // Already covered by a bundled local asset (e.g. a real photo for a
    // Ghanaian dish ARASAAC has no pictogram for) - no need to search.
    if (PictogramAssets.localAssetFor(item.label) != null) {
      return item;
    }

    final pictogramIds = await ArasaacService.searchPictograms(item.label);
    if (pictogramIds.isNotEmpty) {
      return item.copyWith(
        symbolUrl: ArasaacService.getPictogramUrl(pictogramIds.first),
      );
    }
    return item;
  }

  /// Load pictograms for a list of vocabulary items
  static Future<List<VocabularyItem>> loadPictogramsForList(
    List<VocabularyItem> items,
  ) async {
    final List<VocabularyItem> updatedItems = [];
    for (final item in items) {
      final updatedItem = await loadPictogramForWord(item);
      updatedItems.add(updatedItem);
    }
    return updatedItems;
  }
}
