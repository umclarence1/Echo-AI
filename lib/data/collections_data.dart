import '../models/collection.dart';
import '../models/vocabulary_item.dart';
import '../services/arasaac_service.dart';

/// Concept-based collections. Per the PRD, only these expand into a
/// secondary grid - everything else on the board inserts a word directly.
class CollectionsData {
  static List<Collection> getCollections() {
    return [
      Collection(id: 'collection_feel', label: 'Feel', items: _feelItems()),
      Collection(id: 'collection_food', label: 'Food', items: _foodItems()),
      Collection(
        id: 'collection_places',
        label: 'Places',
        items: _placesItems(),
      ),
    ];
  }

  static List<VocabularyItem> _feelItems() {
    // collectionId is set here so the Frequently Used row (which can
    // surface any word from anywhere) knows to route these through the
    // "I" + feeling merge grammar instead of a plain insert.
    const feel = 'collection_feel';
    return [
      VocabularyItem(id: 'feel_happy', label: 'Happy', collectionId: feel, symbolUrl: ArasaacService.getPictogramUrl('35533')),
      VocabularyItem(id: 'feel_sad', label: 'Sad', collectionId: feel, symbolUrl: ArasaacService.getPictogramUrl('35545')),
      VocabularyItem(id: 'feel_angry', label: 'Angry', collectionId: feel, symbolUrl: ArasaacService.getPictogramUrl('35539')),
      VocabularyItem(id: 'feel_scared', label: 'Scared', collectionId: feel, symbolUrl: ArasaacService.getPictogramUrl('35535')),
      VocabularyItem(id: 'feel_excited', label: 'Excited', collectionId: feel, symbolUrl: ArasaacService.getPictogramUrl('39090')),
      VocabularyItem(id: 'feel_tired', label: 'Tired', collectionId: feel, symbolUrl: ArasaacService.getPictogramUrl('35537')),
      VocabularyItem(id: 'feel_sick', label: 'Sick', collectionId: feel, symbolUrl: ArasaacService.getPictogramUrl('7040')),
      VocabularyItem(id: 'feel_confused', label: 'Confused', collectionId: feel, symbolUrl: ArasaacService.getPictogramUrl('2352')),
    ];
  }

  static List<VocabularyItem> _foodItems() {
    return [
      VocabularyItem(id: 'food_rice', label: 'Rice', symbolUrl: ArasaacService.getPictogramUrl('6911')),
      VocabularyItem(id: 'food_bread', label: 'Bread', symbolUrl: ArasaacService.getPictogramUrl('2494')),
      VocabularyItem(id: 'food_water', label: 'Water', symbolUrl: ArasaacService.getPictogramUrl('32464')),
      VocabularyItem(id: 'food_fruit', label: 'Fruit', symbolUrl: ArasaacService.getPictogramUrl('28339')),
      VocabularyItem(id: 'food_soup', label: 'Soup', symbolUrl: ArasaacService.getPictogramUrl('2573')),
      VocabularyItem(id: 'food_snack', label: 'Snack', symbolUrl: ArasaacService.getPictogramUrl('4694')),
      // Real Ghanaian dishes - no ARASAAC pictogram fits these, so they use
      // bundled photos instead (see PictogramAssets).
      VocabularyItem(id: 'food_fufu', label: 'Fufu'),
      VocabularyItem(id: 'food_banku', label: 'Banku'),
      VocabularyItem(id: 'food_kenkey', label: 'Kenkey'),
      VocabularyItem(id: 'food_jollof', label: 'Jollof Rice'),
      VocabularyItem(id: 'food_waakye', label: 'Waakye'),
      VocabularyItem(id: 'food_kelewele', label: 'Kelewele'),
    ];
  }

  static List<VocabularyItem> _placesItems() {
    return [
      VocabularyItem(id: 'place_home', label: 'Home', symbolUrl: ArasaacService.getPictogramUrl('6964')),
      VocabularyItem(id: 'place_school', label: 'School', symbolUrl: ArasaacService.getPictogramUrl('32446')),
      VocabularyItem(id: 'place_hospital', label: 'Hospital', symbolUrl: ArasaacService.getPictogramUrl('36210')),
      VocabularyItem(id: 'place_church', label: 'Church', symbolUrl: ArasaacService.getPictogramUrl('3118')),
      VocabularyItem(id: 'place_market', label: 'Market', symbolUrl: ArasaacService.getPictogramUrl('32942')),
      VocabularyItem(id: 'place_outside', label: 'Outside', symbolUrl: ArasaacService.getPictogramUrl('5475')),
    ];
  }
}
