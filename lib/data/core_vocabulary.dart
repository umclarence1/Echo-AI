import '../models/vocabulary_item.dart';
import '../services/arasaac_service.dart';

class CoreVocabulary {
  static List<VocabularyItem> getItems() {
    return [
      VocabularyItem(
        id: 'core_1',
        label: 'I',
        symbolUrl: ArasaacService.getPictogramUrl('6632'),
        isCore: true,
        position: 0,
      ),
      VocabularyItem(
        id: 'core_2',
        label: 'You',
        symbolUrl: ArasaacService.getPictogramUrl('6625'),
        isCore: true,
        position: 1,
      ),
      VocabularyItem(
        id: 'core_3',
        label: 'Want',
        symbolUrl: ArasaacService.getPictogramUrl('5441'),
        isCore: true,
        position: 2,
      ),
      VocabularyItem(
        id: 'core_4',
        label: 'Need',
        symbolUrl: ArasaacService.getPictogramUrl('37160'),
        isCore: true,
        position: 3,
      ),
      VocabularyItem(
        id: 'core_5',
        label: 'Help',
        symbolUrl: ArasaacService.getPictogramUrl('32648'),
        isCore: true,
        position: 4,
      ),
      VocabularyItem(
        id: 'core_6',
        label: 'Go',
        symbolUrl: ArasaacService.getPictogramUrl('8142'),
        isCore: true,
        position: 5,
      ),
      VocabularyItem(
        id: 'core_7',
        label: 'Stop',
        symbolUrl: ArasaacService.getPictogramUrl('7196'),
        isCore: true,
        position: 6,
      ),
      VocabularyItem(
        id: 'core_8',
        label: 'Please',
        symbolUrl: ArasaacService.getPictogramUrl('8195'),
        isCore: true,
        position: 7,
      ),
      VocabularyItem(
        id: 'core_9',
        label: 'Thank You',
        symbolUrl: ArasaacService.getPictogramUrl('8129'),
        isCore: true,
        position: 8,
      ),
      VocabularyItem(
        id: 'core_10',
        label: 'Yes',
        symbolUrl: ArasaacService.getPictogramUrl('5584'),
        isCore: true,
        position: 9,
      ),
      VocabularyItem(
        id: 'core_11',
        label: 'No',
        symbolUrl: ArasaacService.getPictogramUrl('5526'),
        isCore: true,
        position: 10,
      ),
    ];
  }
}
