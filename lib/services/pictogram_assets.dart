import '../data/library_vocabulary.dart';

/// Maps every known vocabulary label to a pictogram bundled under
/// assets/pictograms/, so the board never needs a network request to show
/// its fixed vocabulary. Ad hoc words (from the on-board search, or
/// People's names) aren't in this map and fall back to a network image.
class PictogramAssets {
  static const Map<String, String> _labelToId = {
    'Airport': '6031',
    'Amen': '3274',
    'Angry': '35539',
    'Bag': '23849',
    'Bathroom': '5921',
    'Bed': '25900',
    'Bible': '23833',
    'Book': '25191',
    'Bread': '2494',
    'Bus': '2262',
    'Buy': '8986',
    'Car': '2339',
    'Check': '29272',
    'Church': '3118',
    'Computer': '7190',
    'Confused': '2352',
    'Doctor': '6561',
    'Excited': '39090',
    'Food': '4610',
    'Friend': '25790',
    'Fruit': '28339',
    'Go': '8142',
    'Happy': '35533',
    'Help': '32648',
    'Home': '6964',
    'Hospital': '36210',
    'I': '6632',
    'Kitchen': '10752',
    'Luggage': '8562',
    'Market': '32942',
    'Medicine': '8163',
    'Menu': '32514',
    'Money': '4630',
    'Need': '37160',
    'No': '5526',
    'Nurse': '6050',
    'Offering': '5529',
    'Outside': '5475',
    'Pain': '2367',
    'Pastor': '30700',
    'Pencil': '2440',
    'Phone': '26479',
    'Play': '23392',
    'Please': '8195',
    'Pray': '24368',
    'Price': '9874',
    'Rest': '16643',
    'Rice': '6911',
    'Sad': '35545',
    'Scared': '35535',
    'School': '32446',
    'Sell': '6652',
    'Seller': '20121',
    'Sick': '7040',
    'Sing': '6960',
    'Snack': '4694',
    'Soup': '2573',
    'Station': '29905',
    'Stop': '7196',
    'TV': '25498',
    'Table': '3129',
    'Teacher': '6556',
    'Thank You': '8129',
    'Ticket': '29208',
    'Tired': '35537',
    'Waiter': '6072',
    'Want': '5441',
    'Water': '32464',
    'Yes': '5584',
    'You': '6625',
    'feel': '3293',
  };

  /// Real photos for Ghanaian-specific items ARASAAC has no pictogram for
  /// (fufu, banku, trotro, etc.) - sourced from Wikimedia Commons, bundled
  /// offline. See lib/data/image_credits.dart for required attribution.
  static const Map<String, String> _labelToPhoto = {
    'Fufu': 'assets/pictograms/ghana/fufu.jpg',
    'Banku': 'assets/pictograms/ghana/banku.jpg',
    'Kenkey': 'assets/pictograms/ghana/kenkey.jpg',
    'Jollof Rice': 'assets/pictograms/ghana/jollof_rice.jpg',
    'Waakye': 'assets/pictograms/ghana/waakye.jpg',
    'Kelewele': 'assets/pictograms/ghana/kelewele.jpg',
    'Trotro': 'assets/pictograms/ghana/trotro.jpg',
  };

  /// Returns the bundled asset path for [label], or null if this word
  /// isn't part of the fixed vocabulary (e.g. a searched word or a
  /// person's name), in which case the network image should be used.
  static String? localAssetFor(String label) {
    final photo = _labelToPhoto[label];
    if (photo != null) return photo;
    final id = _labelToId[label];
    if (id != null) return 'assets/pictograms/$id.png';
    final libraryId = LibraryVocabulary.pictogramIds[label];
    if (libraryId != null) return 'assets/library/$libraryId.png';
    return null;
  }
}
