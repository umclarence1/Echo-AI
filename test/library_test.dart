import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:echo_aac/data/collections_data.dart';
import 'package:echo_aac/data/context_data.dart';
import 'package:echo_aac/data/core_vocabulary.dart';
import 'package:echo_aac/data/library_vocabulary.dart';
import 'package:echo_aac/data/offline_translations_library.dart';

void main() {
  final builtIn = <String>{
    for (final i in CoreVocabulary.getItems()) i.label,
    for (final c in ContextData.getContexts())
      for (final i in c.vocabulary) i.label,
    for (final c in CollectionsData.getCollections())
      for (final i in c.items) i.label,
  };

  test('the library has over a thousand words in organised categories', () {
    expect(LibraryVocabulary.wordCount, greaterThan(1000));
    expect(LibraryVocabulary.categories.length, greaterThanOrEqualTo(15));
    for (final category in LibraryVocabulary.categories) {
      expect(category.words, isNotEmpty, reason: category.label);
    }
  });

  test('no library word repeats another word or a built-in tile', () {
    final seen = <String>{...builtIn};
    for (final category in LibraryVocabulary.categories) {
      for (final word in category.words) {
        expect(seen.add(word.label), isTrue, reason: 'repeated: ${word.label}');
      }
    }
  });

  test('every library word has French and a bundled picture', () {
    for (final category in LibraryVocabulary.categories) {
      for (final code in ['fr']) {
        expect(
          LibraryTranslations.data.containsKey('$code||${category.label}'),
          isTrue,
          reason: '$code name for ${category.label}',
        );
      }
      for (final word in category.words) {
        for (final code in ['fr']) {
          expect(
            LibraryTranslations.data.containsKey('$code||${word.label}'),
            isTrue,
            reason: '$code missing for ${word.label}',
          );
        }
        expect(
          File('assets/library/${word.pictogramId}.png').existsSync(),
          isTrue,
          reason: 'no picture for ${word.label}',
        );
      }
    }
  });

  test('built-in tiles plus the library reach 1000 tiles', () {
    expect(builtIn.length + LibraryVocabulary.wordCount, greaterThan(1000));
  });
}
