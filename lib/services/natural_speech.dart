import '../data/gender_forms.dart';
import '../models/echo_language.dart';
import '../models/vocabulary_item.dart';

/// Suggests a more natural version of the words a person tapped. It never
/// changes anything by itself - the person always chooses whether to use a
/// suggestion. French templates are DRAFT (awaiting native review);
/// Twi and Ga have none yet.
class NaturalSpeech {
  static const _states = {
    'happy', 'sad', 'angry', 'scared', 'excited', 'tired', 'sick', 'confused',
  };

  /// [rawText] is what is in the message box, [items] are the tapped tiles,
  /// [word] translates an English word into [language], and [feminine] picks
  /// feminine adjective forms in French.
  static List<String> suggest({
    required EchoLanguage language,
    required String rawText,
    required List<VocabularyItem> items,
    required String Function(String english) word,
    required bool feminine,
  }) {
    if (rawText.trim().isEmpty) return [];
    switch (language.code) {
      case 'en':
        return _english(rawText, items);
      case 'fr':
        return _romance(language, rawText, items, word, feminine);
      default:
        return [];
    }
  }

  // ------------------------------------------------------------ English

  static List<String> _english(String input, List<VocabularyItem> tapped) {
    final trimmed = input.trim();
    final words = trimmed.split(RegExp(r'\s+'));
    final suggestions = <String>{};

    const pronouns = {'he', 'she', 'they', 'it'};
    if (tapped.length >= 2) {
      final relationship = tapped.last.relationship;
      final preceding = tapped[tapped.length - 2].label.toLowerCase();
      if (relationship != null &&
          relationship.isNotEmpty &&
          pronouns.contains(preceding)) {
        final cap = preceding[0].toUpperCase() + preceding.substring(1);
        suggestions.add('$cap is my ${relationship.toLowerCase()}.');
      }
    }

    const english = {'hungry', ..._states};
    if (words.first.toLowerCase() == 'i' && words.length >= 2) {
      final second = words[1].toLowerCase();
      if (words.length == 2 && english.contains(second)) {
        suggestions.add('I am $second.');
      } else if (words.length >= 3 && (second == 'want' || second == 'need')) {
        final rest = words.sublist(2).join(' ').toLowerCase();
        suggestions.add('I $second $rest.');
        suggestions.add('I $second my $rest.');
      } else if (words.length >= 3 && second == 'feel') {
        final rest = words.sublist(2).join(' ').toLowerCase();
        suggestions.add('I feel $rest.');
      }
    }

    suggestions.add(_tidy(trimmed));
    suggestions.remove(trimmed);
    return suggestions.take(3).toList();
  }

  // ------------------------------------------------------------ French

  static List<String> _romance(
    EchoLanguage lang,
    String rawText,
    List<VocabularyItem> tappedItems,
    String Function(String) word,
    bool feminine,
  ) {
    // The tapped words, without the little "feel" connector tile.
    final items = tappedItems.where((i) => i.id != 'connector_feel').toList();
    final labels = items.map((i) => i.label.toLowerCase()).toList();
    final suggestions = <String>[];

    String adjective(VocabularyItem item) {
      final key = '${lang.code}||${item.label}';
      if (feminine && GenderForms.feminineAdjective.containsKey(key)) {
        return GenderForms.feminineAdjective[key]!.toLowerCase();
      }
      return word(item.label).toLowerCase();
    }

    if (labels.length == 2 && labels[0] == 'i' && _states.contains(labels[1])) {
      final adj = adjective(items[1]);
      suggestions.add('Je suis $adj.');
      suggestions.add('Je me sens $adj.');
    } else if (labels.length >= 3 &&
        labels[0] == 'i' &&
        (labels[1] == 'want' || labels[1] == 'need')) {
      final wanting = labels[1] == 'want';
      final nounItems = items.sublist(2);
      final noun = nounItems.map((i) => word(i.label).toLowerCase()).join(' ');
      {
        final first = nounItems.first.label;
        final vowel = _startsWithVowel(noun);
        final feminineNoun = GenderForms.frenchFeminine.contains(first);
        final possessive = (feminineNoun && !vowel) ? 'ma' : 'mon';
        if (wanting) {
          final partitive = vowel
              ? "de l'"
              : feminineNoun
              ? 'de la '
              : 'du ';
          suggestions.add('Je veux $partitive$noun.');
          suggestions.add('Je veux $possessive $noun.');
        } else {
          final de = vowel ? "d'" : 'de ';
          suggestions.add("J'ai besoin $de$noun.");
          suggestions.add("J'ai besoin de $possessive $noun.");
        }
      }
    }

    final trimmed = rawText.trim();
    suggestions.add(_tidy(trimmed));
    final seen = <String>{};
    return suggestions
        .where((s) => s != trimmed && seen.add(s))
        .take(3)
        .toList();
  }

  static bool _startsWithVowel(String w) {
    if (w.isEmpty) return false;
    return 'aeiouhàâéèêîôû'.contains(w[0]);
  }

  static String _tidy(String text) {
    final lower = text.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}.';
  }
}
