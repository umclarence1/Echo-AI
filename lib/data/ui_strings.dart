/// Menu, button and message text. English and French are written;
/// Twi and Ga fall back to English until native speakers supply them.
/// French is DRAFT, awaiting native review.
/// Placeholders: {w} = a word, {lang} = a language name.
class UiStrings {
  static const Map<String, Map<String, String>> _s = {
    'en': {
      'library_short': 'Words',
      'library': 'Word library',
      'library_search': 'Search all words',
      'library_none': 'No words found.',
      'all_words': 'All',
      'tagline': 'A voice that speaks your language.',
      'get_started': 'Get Started',
      'choose_language': 'Choose your language',
      'change_later': 'You can change this later from Settings.',
      'draft_translation': 'Draft translation',
      'voice_question': 'Would you like Echo to speak in your own voice?',
      'voice_optional':
          'This is optional. If you skip it, Echo speaks with a built-in voice.',
      'record_samples': 'Record Sample Phrases',
      'skip_for_now': 'Skip for now',
      'voice_cloning': 'Voice cloning',
      'voice_soon_onboarding':
          'Recording a personal voice profile is still being built. Echo will use a built-in voice for now - you can set this up later from Settings.',
      'voice_soon':
          'Recording a personal voice profile is still being built. Echo is using a built-in voice for now.',
      'got_it': 'Got it',
      'type_message': 'Type message',
      'select_context': 'Select Context',
      'loading': 'Loading pictograms...',
      'frequently_used': 'Frequently used',
      'speak': 'Speak',
      'delete': 'Delete',
      'clear': 'Clear',
      'nat_title': 'Natural speech suggestions',
      'nat_empty': 'Natural speech suggestions will appear here.',
      'use': 'Use',
      'menu_contexts': 'Contexts',
      'menu_favorites': 'Favorites',
      'menu_voice': 'Voice Profile',
      'menu_settings': 'Settings',
      'menu_about': 'About',
      'emergency': 'Emergency',
      'emergency_title': 'Emergency phrases',
      'people': 'People',
      'add_person': 'Add person',
      'no_people': 'No one added yet. Tap "Add person" to personalize this board.',
      'display_name': 'Display name',
      'relationship_optional': 'Relationship (optional)',
      'relationship_hint': 'e.g. Brother, Teacher',
      'category': 'Category',
      'family': 'Family',
      'friends': 'Friends',
      'professionals': 'Professionals',
      'cancel': 'Cancel',
      'add': 'Add',
      'find_word': 'Find a word',
      'find_word_hint': 'Type a word not on your board',
      'find_word_tooltip': 'Find a word not on your board',
      'search': 'Search',
      'added_word': 'Added "{w}" to your sentence',
      'save_favorite': 'Save to Favorites',
      'no_connection':
          'No connection for speech right now - your message is ready to read or share.',
      'no_voice':
          'No {lang} voice found on this phone. Install one in Settings > Text-to-speech.',
      'create_context': 'Create your own context',
      'context_name': 'Context name',
      'context_name_hint': 'e.g. Grandma\'s house',
      'context_words': 'Words',
      'context_words_hint': 'Separate words with commas: tea, garden, radio',
      'create': 'Create',
      'my_contexts': 'Your contexts',
      'settings_title': 'Settings',
      'natural_speech': 'Natural Speech',
      'natural_speech_sub':
          'Suggest a natural-language version of the words you select. You always choose whether to use it.',
      'switch_scanning': 'Switch Scanning (experimental)',
      'switch_scanning_sub':
          'Highlights core vocabulary tiles one at a time. Press Space, an external switch mapped to a key press, or the on-screen Select button to choose the highlighted tile.',
      'speaker_gender': 'Grammar for "I am..." (French)',
      'speaker_gender_sub':
          'Picks the form of adjectives such as tired: cansado or cansada, fatigué or fatiguée.',
      'masculine': 'Masculine',
      'feminine': 'Feminine',
      'select': 'Select',
      'favorites_title': 'Favorites',
      'favorites_empty':
          'Nothing saved yet. Use the search icon on the board to find a word and save it here for next time.',
      'voice_profile_title': 'Voice Profile',
      'voice_profile_none':
          'No voice profile set up yet. Echo is speaking with a built-in voice.',
      'about_title': 'About Echo',
      'about_body':
          'Echo is an offline-first augmentative and alternative communication (AAC) app built to help people express themselves naturally and confidently.\n\nEcho is designed for any language - it launches with English, Twi, Ga, Ewe, Dagbani and French - so communication reflects who you are.\n\nEcho never changes what you meant to say. It may suggest a clearer phrasing, but you always choose whether to use it.',
      'photo_credits': 'Photo credits',
      'photo_credits_sub':
          'Real photos are used for a few Ghanaian items no pictogram library covers well:',
    },
    'fr': {
      'library_short': 'Mots',
      'library': 'Bibliothèque de mots',
      'library_search': 'Chercher parmi tous les mots',
      'library_none': 'Aucun mot trouvé.',
      'all_words': 'Tous',
      'tagline': 'Une voix qui parle votre langue.',
      'get_started': 'Commencer',
      'choose_language': 'Choisissez votre langue',
      'change_later': 'Vous pourrez la changer plus tard dans les Réglages.',
      'draft_translation': 'Traduction provisoire',
      'voice_question': 'Voulez-vous qu’Echo parle avec votre propre voix ?',
      'voice_optional':
          'C’est facultatif. Si vous passez, Echo parle avec une voix intégrée.',
      'record_samples': 'Enregistrer des phrases',
      'skip_for_now': 'Passer pour l’instant',
      'voice_cloning': 'Clonage de voix',
      'voice_soon_onboarding':
          'Le profil vocal personnel est encore en cours de développement. Echo utilisera une voix intégrée pour l’instant ; vous pourrez le configurer plus tard dans les Réglages.',
      'voice_soon':
          'Le profil vocal personnel est encore en cours de développement. Echo utilise une voix intégrée pour l’instant.',
      'got_it': 'Compris',
      'type_message': 'Saisir un message',
      'select_context': 'Choisir un contexte',
      'loading': 'Chargement des pictogrammes...',
      'frequently_used': 'Les plus utilisés',
      'speak': 'Parler',
      'delete': 'Effacer',
      'clear': 'Vider',
      'nat_title': 'Suggestions de parole naturelle',
      'nat_empty': 'Les suggestions de parole naturelle apparaîtront ici.',
      'use': 'Utiliser',
      'menu_contexts': 'Contextes',
      'menu_favorites': 'Favoris',
      'menu_voice': 'Profil vocal',
      'menu_settings': 'Réglages',
      'menu_about': 'À propos',
      'emergency': 'Urgence',
      'emergency_title': 'Phrases d’urgence',
      'people': 'Personnes',
      'add_person': 'Ajouter une personne',
      'no_people':
          'Personne pour l’instant. Touchez « Ajouter une personne » pour personnaliser ce tableau.',
      'display_name': 'Nom affiché',
      'relationship_optional': 'Relation (facultatif)',
      'relationship_hint': 'ex. Frère, Maîtresse',
      'category': 'Catégorie',
      'family': 'Famille',
      'friends': 'Amis',
      'professionals': 'Professionnels',
      'cancel': 'Annuler',
      'add': 'Ajouter',
      'find_word': 'Chercher un mot',
      'find_word_hint': 'Saisissez un mot absent de votre tableau',
      'find_word_tooltip': 'Chercher un mot absent de votre tableau',
      'search': 'Chercher',
      'added_word': '« {w} » ajouté à votre phrase',
      'save_favorite': 'Enregistrer dans Favoris',
      'no_connection':
          'Pas de connexion pour parler pour l’instant ; votre message est prêt à lire ou à partager.',
      'no_voice':
          'Aucune voix {lang} trouvée sur ce téléphone. Installez-en une dans Réglages > Synthèse vocale.',
      'create_context': 'Créer votre propre contexte',
      'context_name': 'Nom du contexte',
      'context_name_hint': 'ex. Chez mamie',
      'context_words': 'Mots',
      'context_words_hint': 'Séparez les mots par des virgules : thé, jardin, radio',
      'create': 'Créer',
      'my_contexts': 'Vos contextes',
      'settings_title': 'Réglages',
      'natural_speech': 'Parole naturelle',
      'natural_speech_sub':
          'Propose une version en langage naturel des mots choisis. Vous décidez de l’utiliser ou non.',
      'switch_scanning': 'Balayage par contacteur (expérimental)',
      'switch_scanning_sub':
          'Met en évidence les cases de base une par une. Appuyez sur Espace, un contacteur externe ou le bouton Sélectionner pour choisir la case en surbrillance.',
      'speaker_gender': 'Grammaire de « Je suis... » (français)',
      'speaker_gender_sub':
          'Choisit la forme des adjectifs comme fatigué ou fatiguée, cansado ou cansada.',
      'masculine': 'Masculin',
      'feminine': 'Féminin',
      'select': 'Sélectionner',
      'favorites_title': 'Favoris',
      'favorites_empty':
          'Rien d’enregistré pour l’instant. Utilisez l’icône de recherche du tableau pour trouver un mot et l’enregistrer ici.',
      'voice_profile_title': 'Profil vocal',
      'voice_profile_none':
          'Aucun profil vocal pour l’instant. Echo parle avec une voix intégrée.',
      'about_title': 'À propos d’Echo',
      'about_body':
          'Echo est une application de communication alternative et améliorée (CAA) qui fonctionne hors ligne, conçue pour aider chacun à s’exprimer naturellement et avec confiance.\n\nEcho est conçue pour toutes les langues : elle démarre avec l’anglais, le twi, le ga, l’ewe, le dagbani et le français, afin que la communication vous ressemble.\n\nEcho ne change jamais ce que vous vouliez dire. Elle peut suggérer une formulation plus claire, mais vous décidez de l’utiliser ou non.',
      'photo_credits': 'Crédits photo',
      'photo_credits_sub':
          'De vraies photos sont utilisées pour quelques éléments ghanéens que les bibliothèques de pictogrammes couvrent mal :',
    },
  };

  /// Text for [key] in [languageCode]; Twi, Ga and any missing key fall back
  /// to English.
  static String get(String languageCode, String key) {
    return _s[languageCode]?[key] ?? _s['en']![key] ?? key;
  }
}
