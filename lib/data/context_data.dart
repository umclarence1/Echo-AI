import '../models/context.dart';
import '../models/vocabulary_item.dart';
import '../services/arasaac_service.dart';

class ContextData {
  static List<Context> getContexts() {
    return [
      Context(
        id: 'context_home',
        label: 'Home',
        vocabulary: _getHomeVocabulary(),
      ),
      Context(
        id: 'context_hospital',
        label: 'Hospital',
        vocabulary: _getHospitalVocabulary(),
      ),
      Context(
        id: 'context_school',
        label: 'School',
        vocabulary: _getSchoolVocabulary(),
      ),
      Context(
        id: 'context_restaurant',
        label: 'Restaurant',
        vocabulary: _getRestaurantVocabulary(),
      ),
      Context(
        id: 'context_church',
        label: 'Church',
        vocabulary: _getChurchVocabulary(),
      ),
      Context(
        id: 'context_market',
        label: 'Market',
        vocabulary: _getMarketVocabulary(),
      ),
      Context(
        id: 'context_travel',
        label: 'Travel',
        vocabulary: _getTravelVocabulary(),
      ),
    ];
  }

  static List<VocabularyItem> _getChurchVocabulary() {
    return [
      VocabularyItem(id: 'church_1', label: 'Pastor', symbolUrl: ArasaacService.getPictogramUrl('30700'), contexts: ['context_church']),
      VocabularyItem(id: 'church_2', label: 'Bible', symbolUrl: ArasaacService.getPictogramUrl('23833'), contexts: ['context_church']),
      VocabularyItem(id: 'church_3', label: 'Pray', symbolUrl: ArasaacService.getPictogramUrl('24368'), contexts: ['context_church']),
      VocabularyItem(id: 'church_4', label: 'Sing', symbolUrl: ArasaacService.getPictogramUrl('6960'), contexts: ['context_church']),
      VocabularyItem(id: 'church_5', label: 'Offering', symbolUrl: ArasaacService.getPictogramUrl('5529'), contexts: ['context_church']),
      VocabularyItem(id: 'church_6', label: 'Amen', symbolUrl: ArasaacService.getPictogramUrl('3274'), contexts: ['context_church']),
    ];
  }

  static List<VocabularyItem> _getMarketVocabulary() {
    return [
      VocabularyItem(id: 'market_1', label: 'Money', symbolUrl: ArasaacService.getPictogramUrl('4630'), contexts: ['context_market']),
      VocabularyItem(id: 'market_2', label: 'Buy', symbolUrl: ArasaacService.getPictogramUrl('8986'), contexts: ['context_market']),
      VocabularyItem(id: 'market_3', label: 'Sell', symbolUrl: ArasaacService.getPictogramUrl('6652'), contexts: ['context_market']),
      VocabularyItem(id: 'market_4', label: 'Price', symbolUrl: ArasaacService.getPictogramUrl('9874'), contexts: ['context_market']),
      VocabularyItem(id: 'market_5', label: 'Bag', symbolUrl: ArasaacService.getPictogramUrl('23849'), contexts: ['context_market']),
      VocabularyItem(id: 'market_6', label: 'Seller', symbolUrl: ArasaacService.getPictogramUrl('20121'), contexts: ['context_market']),
    ];
  }

  static List<VocabularyItem> _getTravelVocabulary() {
    return [
      VocabularyItem(id: 'travel_1', label: 'Car', symbolUrl: ArasaacService.getPictogramUrl('2339'), contexts: ['context_travel']),
      VocabularyItem(id: 'travel_2', label: 'Bus', symbolUrl: ArasaacService.getPictogramUrl('2262'), contexts: ['context_travel']),
      VocabularyItem(id: 'travel_3', label: 'Ticket', symbolUrl: ArasaacService.getPictogramUrl('29208'), contexts: ['context_travel']),
      VocabularyItem(id: 'travel_4', label: 'Luggage', symbolUrl: ArasaacService.getPictogramUrl('8562'), contexts: ['context_travel']),
      VocabularyItem(id: 'travel_5', label: 'Airport', symbolUrl: ArasaacService.getPictogramUrl('6031'), contexts: ['context_travel']),
      VocabularyItem(id: 'travel_6', label: 'Station', symbolUrl: ArasaacService.getPictogramUrl('29905'), contexts: ['context_travel']),
      // No ARASAAC pictogram fits a trotro - uses a bundled photo instead.
      VocabularyItem(id: 'travel_7', label: 'Trotro', contexts: ['context_travel']),
    ];
  }

  static List<VocabularyItem> _getHomeVocabulary() {
    return [
      VocabularyItem(
        id: 'home_1',
        label: 'Bed',
        symbolUrl: ArasaacService.getPictogramUrl('25900'),
        contexts: ['context_home'],
      ),
      VocabularyItem(
        id: 'home_2',
        label: 'Bathroom',
        symbolUrl: ArasaacService.getPictogramUrl('5921'),
        contexts: ['context_home'],
      ),
      VocabularyItem(
        id: 'home_3',
        label: 'Kitchen',
        symbolUrl: ArasaacService.getPictogramUrl('10752'),
        contexts: ['context_home'],
      ),
      VocabularyItem(
        id: 'home_4',
        label: 'TV',
        symbolUrl: ArasaacService.getPictogramUrl('25498'),
        contexts: ['context_home'],
      ),
      VocabularyItem(
        id: 'home_5',
        label: 'Phone',
        symbolUrl: ArasaacService.getPictogramUrl('26479'),
        contexts: ['context_home'],
      ),
      VocabularyItem(
        id: 'home_6',
        label: 'Food',
        symbolUrl: ArasaacService.getPictogramUrl('4610'),
        contexts: ['context_home'],
      ),
    ];
  }

  static List<VocabularyItem> _getHospitalVocabulary() {
    return [
      VocabularyItem(
        id: 'hospital_1',
        label: 'Doctor',
        symbolUrl: ArasaacService.getPictogramUrl('6561'),
        contexts: ['context_hospital'],
      ),
      VocabularyItem(
        id: 'hospital_2',
        label: 'Nurse',
        symbolUrl: ArasaacService.getPictogramUrl('6050'),
        contexts: ['context_hospital'],
      ),
      VocabularyItem(
        id: 'hospital_3',
        label: 'Medicine',
        symbolUrl: ArasaacService.getPictogramUrl('8163'),
        contexts: ['context_hospital'],
      ),
      VocabularyItem(
        id: 'hospital_4',
        label: 'Pain',
        symbolUrl: ArasaacService.getPictogramUrl('2367'),
        contexts: ['context_hospital'],
      ),
      VocabularyItem(
        id: 'hospital_5',
        label: 'Water',
        symbolUrl: ArasaacService.getPictogramUrl('32464'),
        contexts: ['context_hospital'],
      ),
      VocabularyItem(
        id: 'hospital_6',
        label: 'Rest',
        symbolUrl: ArasaacService.getPictogramUrl('16643'),
        contexts: ['context_hospital'],
      ),
    ];
  }

  static List<VocabularyItem> _getSchoolVocabulary() {
    return [
      VocabularyItem(
        id: 'school_1',
        label: 'Teacher',
        symbolUrl: ArasaacService.getPictogramUrl('6556'),
        contexts: ['context_school'],
      ),
      VocabularyItem(
        id: 'school_2',
        label: 'Book',
        symbolUrl: ArasaacService.getPictogramUrl('25191'),
        contexts: ['context_school'],
      ),
      VocabularyItem(
        id: 'school_3',
        label: 'Pencil',
        symbolUrl: ArasaacService.getPictogramUrl('2440'),
        contexts: ['context_school'],
      ),
      VocabularyItem(
        id: 'school_4',
        label: 'Computer',
        symbolUrl: ArasaacService.getPictogramUrl('7190'),
        contexts: ['context_school'],
      ),
      VocabularyItem(
        id: 'school_5',
        label: 'Friend',
        symbolUrl: ArasaacService.getPictogramUrl('25790'),
        contexts: ['context_school'],
      ),
      VocabularyItem(
        id: 'school_6',
        label: 'Play',
        symbolUrl: ArasaacService.getPictogramUrl('23392'),
        contexts: ['context_school'],
      ),
    ];
  }

  static List<VocabularyItem> _getRestaurantVocabulary() {
    return [
      VocabularyItem(
        id: 'restaurant_1',
        label: 'Menu',
        symbolUrl: ArasaacService.getPictogramUrl('32514'),
        contexts: ['context_restaurant'],
      ),
      VocabularyItem(
        id: 'restaurant_2',
        label: 'Water',
        symbolUrl: ArasaacService.getPictogramUrl('32464'),
        contexts: ['context_restaurant'],
      ),
      VocabularyItem(
        id: 'restaurant_3',
        label: 'Food',
        symbolUrl: ArasaacService.getPictogramUrl('4610'),
        contexts: ['context_restaurant'],
      ),
      VocabularyItem(
        id: 'restaurant_4',
        label: 'Check',
        symbolUrl: ArasaacService.getPictogramUrl('29272'),
        contexts: ['context_restaurant'],
      ),
      VocabularyItem(
        id: 'restaurant_5',
        label: 'Waiter',
        symbolUrl: ArasaacService.getPictogramUrl('6072'),
        contexts: ['context_restaurant'],
      ),
      VocabularyItem(
        id: 'restaurant_6',
        label: 'Table',
        symbolUrl: ArasaacService.getPictogramUrl('3129'),
        contexts: ['context_restaurant'],
      ),
    ];
  }
}
