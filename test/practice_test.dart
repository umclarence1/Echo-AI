import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo_aac/models/echo_language.dart';
import 'package:echo_aac/models/practice.dart';
import 'package:echo_aac/screens/communication_board.dart';
import 'package:echo_aac/screens/practice/practice_screen.dart';
import 'package:echo_aac/screens/practice/practice_session_screen.dart';
import 'package:echo_aac/services/app_settings.dart';
import 'package:echo_aac/services/board_vocabulary.dart';
import 'package:echo_aac/services/pictogram_assets.dart';
import 'package:echo_aac/services/practice_repository.dart';
import 'package:echo_aac/services/practice_run.dart';
import 'package:echo_aac/services/user_data_store.dart';
import 'package:echo_aac/widgets/vocabulary_grid.dart';

const learner = PracticeProfile(id: 'local', name: 'You');
PracticePrompt waterPrompt() => PracticePrompt('water', ['I', 'Want', 'Water']);

PracticeResult result({
  String id = 'result',
  String profile = 'local',
  int count = 2,
  int seconds = 60,
  int? elapsed,
  bool completed = true,
  int day = 1,
}) => PracticeResult(
  id: id,
  profileId: profile,
  startedAt: DateTime.utc(2026, 10, day),
  plannedSeconds: seconds,
  elapsedMs: elapsed ?? seconds * 1000,
  completed: completed,
  deckVersion: PracticePrompts.version,
  responses: [
    for (var i = 0; i < count; i++)
      PracticeResponse(
        promptId: 'water',
        target: 'I want water.',
        answer: 'I Want Water',
        outcome: PracticeOutcome.correct,
        elapsedMs: 0,
      ),
  ],
);

class FailingPracticeRepository extends PracticeRepository {
  bool failSave = true;
  @override
  Future<void> saveResult(PracticeResult result) async {
    if (failSave) throw StateError('Unavailable');
    await super.saveResult(result);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppSettings.language.value = EchoLanguage.english;
    AppSettings.switchScanningEnabled.value = false;
    await UserDataStore.init();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (_) async => 1,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  test(
    'every generated prompt is buildable from available bundled pictograms',
    () {
      final prompts = PracticePrompts.build();
      expect(prompts.length, 52);
      expect(prompts.map((p) => p.id).toSet().length, prompts.length);
      final vocabulary = BoardVocabulary.items.map((i) => i.label).toSet();
      for (final prompt in prompts) {
        for (final word in prompt.words) {
          expect(vocabulary, contains(word));
          expect(PictogramAssets.localAssetFor(word), isNotNull);
        }
        expect(prompt.matches(prompt.words.join(' ')), isTrue);
      }
      expect(waterPrompt().matches(' i   WANT water. '), isTrue);
      expect(waterPrompt().matches('Water I Want'), isFalse);
      expect(waterPrompt().matches('I Want Water Help'), isFalse);
    },
  );

  test(
    'matches count once, wrong checks preserve answer, skips do not increase SPM',
    () {
      var elapsed = Duration.zero;
      final run = PracticeRun(
        profile: learner,
        plannedSeconds: 60,
        prompts: [waterPrompt()],
        elapsed: () => elapsed,
      );
      addTearDown(run.dispose);
      run.check();
      expect(run.started, false);
      run.start();
      run.check();
      run.setAnswer('Water I Want');
      run.check();
      expect(run.answer, 'Water I Want');
      expect(run.sentences, 0);
      elapsed = const Duration(seconds: 10);
      run.setAnswer('I Want Water');
      run.check();
      expect(run.sentences, 1);
      expect(run.answer, '');
      run.check();
      expect(run.sentences, 1);
      run.skip();
      elapsed = const Duration(seconds: 90);
      run.tick();
      final saved = run.result!;
      expect(saved.completed, true);
      expect(saved.elapsedMs, 60000);
      expect(saved.sentencesPerMinute, 1);
      expect(saved.incorrect, 1);
      expect(saved.skipped, 1);
      expect(saved.attempts, 2);
      expect(saved.accuracy, .5);
      expect(saved.responses.map((r) => r.elapsedMs), [0, 10000, 10000]);
      run.check();
      run.skip();
      run.end();
      expect(run.result, same(saved));
    },
  );

  test('late input cannot score even when background timer has not fired', () {
    var elapsed = Duration.zero;
    final run = PracticeRun(
      profile: learner,
      plannedSeconds: 60,
      prompts: [waterPrompt()],
      elapsed: () => elapsed,
    );
    addTearDown(run.dispose);
    run.start();
    run.setAnswer('I Want Water');
    elapsed = const Duration(seconds: 60);
    run.check();
    expect(run.result!.sentences, 0);
    expect(run.result!.responses, isEmpty);
    expect(run.result!.completed, true);
  });

  test(
    'early session uses actual elapsed time and no-attempt accuracy is absent',
    () {
      var elapsed = Duration.zero;
      final run = PracticeRun(
        profile: learner,
        plannedSeconds: 120,
        prompts: [waterPrompt()],
        elapsed: () => elapsed,
      );
      addTearDown(run.dispose);
      run.start();
      elapsed = const Duration(seconds: 30);
      run.setAnswer('I Want Water');
      run.check();
      run.end();
      expect(run.result!.completed, false);
      expect(run.result!.elapsedMs, 30000);
      expect(run.result!.sentencesPerMinute, 2);
      expect(result(count: 0).accuracy, isNull);
      expect(() => result(elapsed: 0), throwsFormatException);
    },
  );

  test(
    'prompt deck visits every prompt before repeating and avoids adjacent repeats',
    () {
      final deck = PracticePrompts.build();
      final run = PracticeRun(
        profile: learner,
        plannedSeconds: 300,
        prompts: deck,
        random: Random(9),
        elapsed: () => const Duration(seconds: 1),
      );
      addTearDown(run.dispose);
      run.start();
      final seen = <String>{};
      String? previous;
      for (var i = 0; i < deck.length * 2; i++) {
        expect(run.prompt.id, isNot(previous));
        previous = run.prompt.id;
        if (i < deck.length) expect(seen.add(run.prompt.id), true);
        run.setAnswer(run.prompt.words.join(' '));
        run.check();
      }
      expect(run.sentences, deck.length * 2);
    },
  );

  test(
    'profiles and result details survive reload, retries, and concurrent saves',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prepared_boards_v1', 'untouched boards');
      final repository = PracticeRepository();
      await repository.addProfile(
        const PracticeProfile(id: 'sam', name: 'Sam'),
      );
      await Future.wait([
        repository.saveResult(result(id: 'one')),
        PracticeRepository().saveResult(result(id: 'two', profile: 'sam')),
      ]);
      await repository.saveResult(result(id: 'two', profile: 'sam'));
      var data = await PracticeRepository().load();
      expect(data.profiles.map((p) => p.name), ['You', 'Sam']);
      expect(data.selectedProfileId, 'sam');
      expect(data.results.length, 2);
      expect(data.results.last.responses.first.answer, 'I Want Water');
      await repository.clearHistory('sam');
      data = await repository.load();
      expect(data.results.single.profileId, 'local');
      expect(data.profiles.length, 2);
      expect(prefs.getString('prepared_boards_v1'), 'untouched boards');
    },
  );

  test(
    'corrupt or future practice data cannot be overwritten by a save',
    () async {
      final prefs = await SharedPreferences.getInstance();
      for (final raw in [
        'invalid json',
        jsonEncode({'schemaVersion': 2}),
        jsonEncode({
          'schemaVersion': 1,
          'profiles': [],
          'results': [],
          'selectedProfileId': 'missing',
        }),
      ]) {
        await prefs.setString(PracticeRepository.storageKey, raw);
        await expectLater(
          PracticeRepository().saveResult(result()),
          throwsA(anything),
        );
        expect(prefs.getString(PracticeRepository.storageKey), raw);
      }
    },
  );

  Future<void> phone(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  Future<void> tile(WidgetTester tester, String label) async {
    final finder = find
        .byWidgetPredicate((w) => w is VocabularyTile && w.item.label == label)
        .first;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'practice is reachable from the main menu and supports learner creation',
    (tester) async {
      await phone(tester, const CommunicationBoard());
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();
      expect(find.text('Start practice'), findsOneWidget);
      await tester.tap(find.text('Add learner'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Sam');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect((await PracticeRepository().load()).selectedProfile.name, 'Sam');
      expect(find.text('Sam'), findsOneWidget);
      AppSettings.language.value = EchoLanguage.french;
      await tester.ensureVisible(find.text('Start practice'));
      await tester.tap(find.text('Start practice'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('practice_prompt')), findsOneWidget);
      expect(AppSettings.language.value, EchoLanguage.french);
      await tester.tap(find.text('End session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End session').last);
      await tester.pumpAndSettle();
      expect(find.text('Session ended'), findsOneWidget);
      await tester.tap(find.text('Back to practice'));
      await tester.pumpAndSettle();
      expect(find.text('Start practice'), findsOneWidget);
      expect(
        (await PracticeRepository().load()).results.single.profileId,
        (await PracticeRepository().load()).selectedProfileId,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'phone session uses real board navigation, scores corrections, and saves on timeout',
    (tester) async {
      var elapsed = Duration.zero;
      final run = PracticeRun(
        profile: learner,
        plannedSeconds: 60,
        prompts: [waterPrompt()],
        elapsed: () => elapsed,
      );
      await phone(
        tester,
        PracticeSessionScreen(
          profile: learner,
          plannedSeconds: 60,
          repository: PracticeRepository(),
          run: run,
        ),
      );
      expect(run.started, true);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).readOnly,
        true,
      );
      await tile(tester, 'I');
      await tile(tester, 'Need');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(run.sentences, 0);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tile(tester, 'Want');
      // Water lives in the Food collection, opened from the regular board UI.
      await tester.drag(
        find.byKey(const ValueKey('board_collections')),
        const Offset(-140, 0),
      );
      await tester.pumpAndSettle();
      final food = find.byKey(const ValueKey('collection_food'));
      await tester.ensureVisible(food);
      await tester.tap(food);
      await tester.pumpAndSettle();
      await tile(tester, 'Water');
      elapsed = const Duration(seconds: 12);
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(run.sentences, 1);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '',
      );
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(run.sentences, 1);
      elapsed = const Duration(seconds: 65);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Practice result'), findsOneWidget);
      expect(find.text('1.0 sentences per minute'), findsOneWidget);
      final saved = (await PracticeRepository().load()).results.single;
      expect(saved.sentences, 1);
      expect(saved.incorrect, 1);
      expect(saved.elapsedMs, 60000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'expiration closes the library and save failure can be retried without duplicates',
    (tester) async {
      var elapsed = Duration.zero;
      final repository = FailingPracticeRepository();
      final run = PracticeRun(
        profile: learner,
        plannedSeconds: 60,
        prompts: [waterPrompt()],
        elapsed: () => elapsed,
      );
      await phone(
        tester,
        PracticeSessionScreen(
          profile: learner,
          plannedSeconds: 60,
          repository: repository,
          run: run,
        ),
      );
      await tester.tap(find.text('Words'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      elapsed = const Duration(minutes: 1);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Retry saving'), findsOneWidget);
      expect((await repository.load()).results, isEmpty);
      repository.failSave = false;
      await tester.tap(find.text('Retry saving'));
      await tester.pumpAndSettle();
      expect((await repository.load()).results.length, 1);
      expect(find.textContaining('Saved to this learner'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'best and progress exclude early results, other learners and other durations',
    (tester) async {
      final repository = PracticeRepository();
      await repository.addProfile(
        const PracticeProfile(id: 'sam', name: 'Sam'),
      );
      await repository.saveResult(result(id: 'previous', count: 1, day: 1));
      await repository.saveResult(result(id: 'latest', count: 2, day: 2));
      await repository.saveResult(
        result(id: 'early', count: 20, elapsed: 1000, completed: false),
      );
      await repository.saveResult(result(id: 'long', count: 12, seconds: 120));
      await repository.saveResult(
        result(id: 'other', count: 30, profile: 'sam'),
      );
      await repository.selectProfile('local');
      await phone(tester, PracticeScreen(repository: repository));
      await tester.scrollUntilVisible(
        find.text('Personal best · 1-minute timed sessions'),
        250,
      );
      expect(find.text('2.0 sentences per minute'), findsOneWidget);
      expect(
        find.text('+1.0 SPM compared with the previous 1-minute run'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'landscape practice scrolls without overflow and records skipped early sessions',
    (tester) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var elapsed = Duration.zero;
      final run = PracticeRun(
        profile: learner,
        plannedSeconds: 60,
        prompts: [waterPrompt()],
        elapsed: () => elapsed,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PracticeSessionScreen(
            profile: learner,
            plannedSeconds: 60,
            repository: PracticeRepository(),
            run: run,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      elapsed = const Duration(seconds: 30);
      await tester.tap(find.text('End session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End session').last);
      await tester.pumpAndSettle();
      final saved = (await PracticeRepository().load()).results.single;
      expect(saved.completed, false);
      expect(saved.elapsedMs, 30000);
      expect(saved.sentences, 0);
      expect(saved.skipped, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('food collection scrolls to pictograms below the first rows', (
    tester,
  ) async {
    final run = PracticeRun(
      profile: learner,
      plannedSeconds: 60,
      prompts: [
        PracticePrompt('food', ['I', 'Want', 'Kelewele']),
      ],
      elapsed: () => const Duration(seconds: 5),
    );
    await phone(
      tester,
      PracticeSessionScreen(
        profile: learner,
        plannedSeconds: 60,
        repository: PracticeRepository(),
        run: run,
      ),
    );
    await tile(tester, 'I');
    await tile(tester, 'Want');
    final collections = find.byKey(const ValueKey('board_collections'));
    await tester.ensureVisible(collections);
    await tester.drag(collections, const Offset(-140, 0));
    await tester.pumpAndSettle();
    final food = find.byKey(const ValueKey('collection_food'));
    await tester.ensureVisible(food);
    await tester.tap(food);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('collection_words')),
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();
    await tile(tester, 'Kelewele');
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(run.sentences, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
