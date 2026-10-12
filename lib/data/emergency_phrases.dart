import '../models/echo_language.dart';

/// One quick phrase for an emergency, in each language that has it.
class EmergencyPhrase {
  final String english;
  final String? french;

  const EmergencyPhrase(this.english, {this.french});

  /// The phrase in [language], or null when that language has none yet.
  String? inLanguage(EchoLanguage language) {
    switch (language.code) {
      case 'en':
        return english;
      case 'fr':
        return french;
      default:
        return null;
    }
  }
}

/// Phrases someone may need to say fast. French is DRAFT,
/// awaiting native review. Twi, Ga, Ewe and Dagbani are empty until native speakers write
/// them - in those languages Echo speaks the English phrase instead, so an
/// emergency is never silent.
class EmergencyPhrases {
  static const List<EmergencyPhrase> all = [
    EmergencyPhrase(
      'I need help.',
      french: "J'ai besoin d'aide.",
    ),
    EmergencyPhrase(
      'I am in pain.',
      french: "J'ai mal.",
    ),
    EmergencyPhrase(
      "I can't breathe.",
      french: "Je n'arrive pas à respirer.",
    ),
    EmergencyPhrase(
      'Call a doctor.',
      french: 'Appelez un médecin.',
    ),
    EmergencyPhrase(
      'I feel sick.',
      french: 'Je me sens mal.',
    ),
    EmergencyPhrase(
      'I need water.',
      french: "J'ai besoin d'eau.",
    ),
    EmergencyPhrase(
      'I need the toilet.',
      french: "J'ai besoin d'aller aux toilettes.",
    ),
    EmergencyPhrase(
      'I am scared.',
      french: "J'ai peur.",
    ),
    EmergencyPhrase(
      'Call my family.',
      french: 'Appelez ma famille.',
    ),
    EmergencyPhrase(
      'Please stop.',
      french: "Arrêtez, s'il vous plaît.",
    ),
  ];
}
