/// Grammar data for French. DRAFT: awaiting native review.
class GenderForms {
  /// Feminine form of the feeling adjectives, keyed "lang||English word".
  /// A speaker who is a woman says "cansada" / "fatiguée"; the default
  /// (masculine) forms live in ExtraTranslations.
  static const Map<String, String> feminineAdjective = {
    'fr||Happy': 'Heureuse',
    'fr||Sad': 'Triste',
    'fr||Angry': 'En colère',
    'fr||Scared': 'Effrayée',
    'fr||Excited': 'Enthousiaste',
    'fr||Tired': 'Fatiguée',
    'fr||Sick': 'Malade',
    'fr||Confused': 'Confuse',
  };

  /// Gender of French nouns that follow "want" and "need", by English word.
  /// Anything not listed is treated as masculine.
  static const Set<String> frenchFeminine = {
    'Water', 'Food', 'Soup', 'Snack', 'Car', 'Table', 'Kitchen', 'Pain',
    'Bible', 'Offering', 'Station',
  };
}
