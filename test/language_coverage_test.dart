import 'package:flutter_test/flutter_test.dart';

import 'package:echo_aac/data/collections_data.dart';
import 'package:echo_aac/data/context_data.dart';
import 'package:echo_aac/data/core_vocabulary.dart';
import 'package:echo_aac/data/offline_translations_extra.dart';
import 'package:echo_aac/models/echo_language.dart';

void main() {
  // Every word the board shows: tiles plus context and collection names.
  Set<String> boardWords() {
    final words = <String>{'feel', 'People'};
    for (final item in CoreVocabulary.getItems()) {
      words.add(item.label);
    }
    for (final context in ContextData.getContexts()) {
      words.add(context.label);
      for (final item in context.vocabulary) {
        words.add(item.label);
      }
    }
    for (final collection in CollectionsData.getCollections()) {
      words.add(collection.label);
      for (final item in collection.items) {
        words.add(item.label);
      }
    }
    return words;
  }

  test('French covers every word on the board', () {
    for (final lang in [EchoLanguage.french]) {
      final missing = boardWords()
          .where((w) => !ExtraTranslations.data.containsKey('${lang.code}||$w'))
          .toList();
      expect(missing, isEmpty, reason: '${lang.label} is missing: $missing');
    }
  });

  test('every language has a unique code and a way to speak', () {
    final codes = EchoLanguage.all.map((l) => l.code).toSet();
    expect(codes.length, EchoLanguage.all.length);
    for (final lang in EchoLanguage.all) {
      expect(
        lang.prefersKhayaVoice || lang.voiceLocale != null,
        isTrue,
        reason: '${lang.label} has no voice',
      );
    }
  });
}
