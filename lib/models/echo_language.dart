/// A language Echo can show and speak. Adding a language means adding one
/// entry to [EchoLanguage.all] plus its word list in
/// lib/data/offline_translations_extra.dart (or fetch its words from Khaya AI)
/// - nothing else changes.
class EchoLanguage {
  /// App-wide key, also used in translation cache keys ("code||English label").
  final String code;

  /// The language's own name, shown in pickers.
  final String label;

  /// Code understood by the Khaya AI API, or null if Khaya doesn't cover it.
  final String? khayaCode;

  /// BCP-47 locale for the phone's built-in voice, or null if the phone has
  /// no voice for this language (Twi, Ga, Ewe and Dagbani).
  final String? voiceLocale;

  /// Speak through Khaya first (needs internet), then fall back to the phone.
  final bool prefersKhayaVoice;

  /// True while a native speaker has not yet reviewed the word list.
  final bool isDraft;

  /// Replaces the leading "I" when a feeling is chosen, e.g. "Je me sens"
  /// turns "I" + "Happy" into "Je me sens heureux". Null keeps the default
  /// "I feel happy" word-by-word merge.
  final String? feelPrefix;

  const EchoLanguage({
    required this.code,
    required this.label,
    this.khayaCode,
    this.voiceLocale,
    this.prefersKhayaVoice = false,
    this.isDraft = false,
    this.feelPrefix,
  });

  bool get isEnglish => code == 'en';

  static const english = EchoLanguage(
    code: 'en',
    label: 'English',
    voiceLocale: 'en-US',
    // Khaya's English voice is trained for a Ghanaian speaker, not a neutral
    // native accent - fine for Twi/Ga/Ewe/Dagbani, where it's the only
    // option, but not for English, where the phone's own native voice
    // sounds more natural and costs no Khaya quota.
  );

  static const twi = EchoLanguage(
    code: 'tw',
    label: 'Twi',
    khayaCode: 'tw',
    prefersKhayaVoice: true,
  );

  static const ga = EchoLanguage(
    code: 'gaa',
    label: 'Ga',
    khayaCode: 'gaa',
    prefersKhayaVoice: true,
  );

  static const ewe = EchoLanguage(
    code: 'ee',
    label: 'Ewe',
    khayaCode: 'ee',
    prefersKhayaVoice: true,
    isDraft: true,
  );

  static const dagbani = EchoLanguage(
    code: 'dag',
    label: 'Dagbani',
    khayaCode: 'dag',
    prefersKhayaVoice: true,
    isDraft: true,
  );

  static const french = EchoLanguage(
    code: 'fr',
    label: 'Français',
    voiceLocale: 'fr-FR',
    isDraft: true,
    feelPrefix: 'Je me sens',
  );

  static const all = [english, twi, ga, ewe, dagbani, french];
}
