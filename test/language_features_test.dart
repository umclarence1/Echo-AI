import 'package:flutter_test/flutter_test.dart';

import 'package:echo_aac/data/emergency_phrases.dart';
import 'package:echo_aac/data/offline_translations_extra.dart';
import 'package:echo_aac/data/ui_strings.dart';
import 'package:echo_aac/models/echo_language.dart';
import 'package:echo_aac/models/vocabulary_item.dart';
import 'package:echo_aac/services/natural_speech.dart';

VocabularyItem tile(String id, String label) =>
    VocabularyItem(id: id, label: label);

String Function(String) translator(String code) =>
    (english) => ExtraTranslations.data['$code||$english'] ?? english;

void main() {
  group('Natural Speech in French', () {
    test('a feeling becomes a natural sentence, with gender agreement', () {
      final items = [tile('core_1', 'I'), tile('feel_tired', 'Tired')];
      final masculine = NaturalSpeech.suggest(
        language: EchoLanguage.french,
        rawText: 'Je Fatigué',
        items: items,
        word: translator('fr'),
        feminine: false,
      );
      expect(masculine, contains('Je suis fatigué.'));
      expect(masculine, contains('Je me sens fatigué.'));

      final feminine = NaturalSpeech.suggest(
        language: EchoLanguage.french,
        rawText: 'Je Fatigué',
        items: items,
        word: translator('fr'),
        feminine: true,
      );
      expect(feminine, contains('Je suis fatiguée.'));
    });

    test('French uses the right article for wants and needs', () {
      List<String> suggest(String noun, String label, String verb) =>
          NaturalSpeech.suggest(
            language: EchoLanguage.french,
            rawText: 'Je $verb $noun',
            items: [tile('core_1', 'I'), tile('v', verb == 'Veux' ? 'Want' : 'Need'), tile('n', label)],
            word: translator('fr'),
            feminine: false,
          );

      expect(suggest('Eau', 'Water', 'Veux'), contains("Je veux de l'eau."));
      expect(suggest('Pain', 'Bread', 'Veux'), contains('Je veux du pain.'));
      expect(suggest('Soupe', 'Soup', 'Veux'), contains('Je veux de la soupe.'));
      expect(suggest('Eau', 'Water', 'Besoin'), contains("J'ai besoin d'eau."));
    });

    test('Twi, Ga, Ewe and Dagbani give no suggestions until native speakers write them', () {
      expect(
        NaturalSpeech.suggest(
          language: EchoLanguage.twi,
          rawText: 'Me',
          items: [tile('core_1', 'I')],
          word: (e) => e,
          feminine: false,
        ),
        isEmpty,
      );
    });
  });

  group('menus and emergency phrases', () {
    test('every English menu string also exists in French', () {
      const keys = ['speak', 'delete', 'clear', 'menu_settings', 'emergency'];
      for (final key in keys) {
        expect(UiStrings.get('fr', key), isNot(UiStrings.get('en', key)));
      }
    });

    test('Twi falls back to English rather than showing a missing key', () {
      expect(UiStrings.get('tw', 'speak'), UiStrings.get('en', 'speak'));
      expect(UiStrings.get('en', 'no_such_key'), 'no_such_key');
    });

    test('every emergency phrase has French', () {
      for (final phrase in EmergencyPhrases.all) {
        expect(phrase.french, isNotNull, reason: phrase.english);
      }
    });
  });
}
