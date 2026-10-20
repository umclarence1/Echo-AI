import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo_aac/models/echo_language.dart';
import 'package:echo_aac/models/prepared_board.dart';
import 'package:echo_aac/models/vocabulary_item.dart';
import 'package:echo_aac/screens/communication_board.dart';
import 'package:echo_aac/screens/boards/board_present_screen.dart';
import 'package:echo_aac/services/app_settings.dart';
import 'package:echo_aac/services/user_data_store.dart';
import 'package:echo_aac/services/tense_converter.dart';
import 'package:echo_aac/widgets/vocabulary_grid.dart';
import 'package:echo_aac/widgets/tense_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  String convert(String input, SentenceTense tense) =>
      TenseConverter.convert(input, tense, 'en').text;

  test('simple statements support all three tenses without altering names', () {
    expect(convert('I Want Water', SentenceTense.past), 'I wanted Water');
    expect(
      convert('I want water.', SentenceTense.future),
      'I will want water.',
    );
    expect(
      convert('She went to Accra!', SentenceTense.present),
      'She goes to Accra!',
    );
    expect(convert('They eat rice', SentenceTense.past), 'They ate rice');
    expect(convert('I will drink water', SentenceTense.past), 'I drank water');
    expect(
      convert('He has a book', SentenceTense.future),
      'He will have a book',
    );
    expect(convert('I have a red bag', SentenceTense.past), 'I had a red bag');
    expect(convert('I feel happy', SentenceTense.past), 'I felt happy');
  });
  test('copula, state phrases, agreement and negatives', () {
    expect(convert('I am hungry', SentenceTense.past), 'I was hungry');
    expect(convert('You are happy.', SentenceTense.past), 'You were happy.');
    expect(convert('I hungry', SentenceTense.future), 'I will be hungry');
    expect(
      convert('She was not happy', SentenceTense.future),
      'She will not be happy',
    );
    expect(
      convert('They will not be tired', SentenceTense.present),
      'They are not tired',
    );
    expect(
      convert("He doesn't want water", SentenceTense.past),
      'He did not want water',
    );
    expect(
      convert('She did not eat rice', SentenceTense.present),
      'She does not eat rice',
    );
    expect(
      convert("I won't go to school", SentenceTense.past),
      'I did not go to school',
    );
  });
  test(
    'unsupported languages, questions and complex grammar stay unchanged',
    () {
      for (final text in [
        'Water',
        'Can I go?',
        'I am eating rice',
        'I have eaten rice',
        'I want water and I need help',
        'I went yesterday',
        'I dance',
      ]) {
        final result = TenseConverter.convert(text, SentenceTense.future, 'en');
        expect(result.supported, false, reason: text);
        expect(result.text, text);
      }
      for (final code in ['fr', 'tw', 'gaa', 'ee', 'dag']) {
        final result = TenseConverter.convert(
          'I want water',
          SentenceTense.past,
          code,
        );
        expect(result.supported, false);
        expect(result.text, 'I want water');
      }
    },
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppSettings.language.value = EchoLanguage.english;
    AppSettings.switchScanningEnabled.value = false;
    await UserDataStore.init();
  });

  Future<void> choose(WidgetTester tester, String label) async {
    final selector = find.byKey(const ValueKey('tense_selector'));
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'main board preserves source across tense changes, edits and clear',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: CommunicationBoard()));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<SentenceTense>>(
              find.byKey(const ValueKey('tense_selector')),
            )
            .value,
        SentenceTense.present,
      );
      final field = find.byType(TextField).first;
      await tester.enterText(field, 'I want water');
      await choose(tester, 'Past');
      expect(
        tester.widget<TextField>(field).controller!.text,
        'I wanted water',
      );
      await choose(tester, 'Future');
      expect(
        tester.widget<TextField>(field).controller!.text,
        'I will want water',
      );
      tester.widget<TextField>(field).controller!.selection =
          const TextSelection.collapsed(offset: 2);
      await tester.pump();
      expect(
        tester
            .widget<DropdownButton<SentenceTense>>(
              find.byKey(const ValueKey('tense_selector')),
            )
            .value,
        SentenceTense.future,
      );
      await choose(tester, 'Present');
      expect(tester.widget<TextField>(field).controller!.text, 'I want water');
      await tester.enterText(field, 'I ate rice');
      await choose(tester, 'Present');
      expect(tester.widget<TextField>(field).controller!.text, 'I eat rice');
      await choose(tester, 'Future');
      await tester.tap(find.text('Clear').first);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, '');
      expect(
        tester
            .widget<DropdownButton<SentenceTense>>(
              find.byKey(const ValueKey('tense_selector')),
            )
            .value,
        SentenceTense.present,
      );
      Future<void> tapWord(String label) async {
        final tile = find
            .byWidgetPredicate(
              (w) => w is VocabularyTile && w.item.label == label,
            )
            .first;
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
      }

      await tapWord('I');
      await tapWord('Want');
      await choose(tester, 'Past');
      expect(tester.widget<TextField>(field).controller!.text, 'I wanted');
      await tapWord('Help');
      expect(tester.widget<TextField>(field).controller!.text, 'I wanted Help');
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, 'I wanted');
      await choose(tester, 'Present');
      expect(tester.widget<TextField>(field).controller!.text, 'I want');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('other languages disable conversion with a visible explanation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenseSelector(
            value: SentenceTense.present,
            source: 'Je veux de l’eau',
            languageCode: 'fr',
            onChanged: (_) => fail('Unsupported language should be disabled'),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<DropdownButton<SentenceTense>>(
            find.byKey(const ValueKey('tense_selector')),
          )
          .onChanged,
      isNull,
    );
    expect(
      find.textContaining('simple English statements only'),
      findsOneWidget,
    );
  });

  testWidgets(
    'presentation speaks converted text, preserves tiles, resets clear',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final spoken = <Object?>[];
      const channel = MethodChannel('flutter_tts');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'speak') spoken.add(call.arguments);
            return call.method == 'isLanguageAvailable' ? true : 1;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final board = PreparedBoard(
        id: 'test',
        title: 'Test',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        sections: [
          BoardSection(
            id: 's',
            title: 'Talk',
            items: [
              for (final w in ['I', 'Want', 'Water'])
                VocabularyItem(id: w, label: w),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: BoardPresentScreen(board: board)),
      );
      await tester.pumpAndSettle();
      for (final tile in find.byType(VocabularyTile).evaluate().toList()) {
        await tester.tap(find.byWidget(tile.widget));
        await tester.pumpAndSettle();
      }
      await choose(tester, 'Past');
      expect(find.text('I wanted Water'), findsOneWidget);
      await choose(tester, 'Future');
      expect(find.text('I will want Water'), findsOneWidget);
      await tester.ensureVisible(find.text('Speak'));
      await tester.tap(find.text('Speak'));
      await tester.pumpAndSettle();
      expect(spoken.toString(), contains('I will want Water'));
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('I will want'), findsOneWidget);
      expect(board.sections.first.items.map((i) => i.label), [
        'I',
        'Want',
        'Water',
      ]);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<SentenceTense>>(
              find.byKey(const ValueKey('tense_selector')),
            )
            .value,
        SentenceTense.present,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
