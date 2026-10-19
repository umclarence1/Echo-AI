import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo_aac/models/echo_language.dart';
import 'package:echo_aac/models/prepared_board.dart';
import 'package:echo_aac/models/vocabulary_item.dart';
import 'package:echo_aac/screens/boards/boards_screen.dart';
import 'package:echo_aac/screens/boards/board_present_screen.dart';
import 'package:echo_aac/services/app_settings.dart';
import 'package:echo_aac/services/board_repository.dart';
import 'package:echo_aac/services/board_vocabulary.dart';
import 'package:echo_aac/services/language_scope.dart';
import 'package:echo_aac/services/pictogram_assets.dart';
import 'package:echo_aac/widgets/vocabulary_grid.dart';

PreparedBoard sampleBoard() => PreparedBoard(
  id: 'saved_board',
  title: 'School talk',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  sections: [
    BoardSection(
      id: 'intro',
      title: 'Introduction',
      items: [
        VocabularyItem(id: 'hello', label: 'Hello'),
        VocabularyItem(id: 'water', label: 'Water'),
      ],
    ),
    BoardSection(
      id: 'questions',
      title: 'Questions',
      items: [VocabularyItem(id: 'help', label: 'Help')],
    ),
  ],
);

class FailingBoardRepository extends BoardRepository {
  @override
  Future<void> save(PreparedBoard board) async =>
      throw StateError('Storage unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettings.language.value = EchoLanguage.english;
    AppSettings.switchScanningEnabled.value = false;
  });

  test(
    'boards preserve order, symbols and unrelated data across repository instances',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('favorites_v1', 'leave this unchanged');
      final board = sampleBoard();
      await BoardRepository().save(board);
      final restored = (await BoardRepository().load()).single;
      expect(restored.sections.map((s) => s.title), [
        'Introduction',
        'Questions',
      ]);
      expect(restored.sections.first.items.map((i) => i.label), [
        'Hello',
        'Water',
      ]);
      await BoardRepository().save(
        restored.copyWith(sections: restored.sections.reversed.toList()),
      );
      expect(
        (await BoardRepository().load()).single.sections.first.title,
        'Questions',
      );
      expect(prefs.getString('favorites_v1'), 'leave this unchanged');
    },
  );

  test('a duplicate can be edited or deleted independently', () async {
    final repository = BoardRepository();
    final original = sampleBoard();
    final copy = original.duplicate('School talk (copy)');
    expect(copy.id, isNot(original.id));
    expect(copy.sections.first.id, isNot(original.sections.first.id));
    await repository.save(original);
    await repository.save(copy.copyWith(sections: []));
    await repository.delete(copy.id);
    expect((await repository.load()).single.toJson(), original.toJson());
  });

  test('unreadable and future-version data are never overwritten', () async {
    final prefs = await SharedPreferences.getInstance();
    for (final raw in [
      'invalid JSON',
      jsonEncode({'schemaVersion': 99, 'boards': []}),
    ]) {
      await prefs.setString(BoardRepository.storageKey, raw);
      await expectLater(
        BoardRepository().save(sampleBoard()),
        throwsA(isA<FormatException>()),
      );
      expect(prefs.getString(BoardRepository.storageKey), raw);
    }
  });

  test('catalogue entries have unique labels and bundled pictures', () {
    expect(
      BoardVocabulary.items.map((i) => i.label.toLowerCase()).toSet().length,
      BoardVocabulary.items.length,
    );
    for (final item in BoardVocabulary.items) {
      expect(
        PictogramAssets.localAssetFor(item.label),
        isNotNull,
        reason: item.label,
      );
    }
  });

  Future<void> mount(
    WidgetTester tester,
    Widget screen, {
    double width = 360,
    double height = 800,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      LanguageScope(
        language: AppSettings.language,
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> nameDialog(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextFormField), text);
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'create, group, select several pictures, save and reopen on a phone',
    (tester) async {
      await mount(tester, const BoardsScreen());
      await tester.tap(find.text('Create board'));
      await tester.pumpAndSettle();
      await nameDialog(tester, 'My presentation');
      await tester.tap(find.text('Add section'));
      await tester.pumpAndSettle();
      await nameDialog(tester, 'Opening');
      await tester.tap(find.text('Choose pictograms'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'water');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Water').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hello').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done (2)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('My presentation'), findsOneWidget);
      final stored = (await BoardRepository().load()).single;
      expect(
        stored.sections.single.items.map((i) => i.label),
        containsAll(['Hello', 'Water']),
      );
      await tester.tap(find.text('My presentation'));
      await tester.pumpAndSettle();
      expect(find.text('Opening'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('discard leaves the saved board intact', (tester) async {
    await BoardRepository().save(sampleBoard());
    await mount(tester, const BoardsScreen());
    await tester.tap(find.text('School talk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Rename board'));
    await tester.pumpAndSettle();
    await nameDialog(tester, 'Changed title');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect((await BoardRepository().load()).single.title, 'School talk');
    expect(find.text('School talk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reorder tiles, move between sections, and reorder sections', (
    tester,
  ) async {
    await BoardRepository().save(sampleBoard());
    await mount(tester, const BoardsScreen());
    await tester.tap(find.text('School talk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tile options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move tile later'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tile options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to section'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(SimpleDialog),
        matching: find.text('Questions'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Section options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move section later'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final board = (await BoardRepository().load()).single;
    expect(board.sections.map((s) => s.title), ['Questions', 'Introduction']);
    expect(board.sections.first.items.map((i) => i.label), ['Help', 'Water']);
    expect(board.sections.last.items.single.label, 'Hello');
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed save keeps edits open and leaves stored data intact', (
    tester,
  ) async {
    await BoardRepository().save(sampleBoard());
    await mount(tester, BoardsScreen(repository: FailingBoardRepository()));
    await tester.tap(find.text('School talk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Rename board'));
    await tester.pumpAndSettle();
    await nameDialog(tester, 'Still editing');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Still editing'), findsOneWidget);
    expect(find.textContaining('Could not save.'), findsOneWidget);
    expect((await BoardRepository().load()).single.title, 'School talk');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'presentation builds a message and navigates sections at narrow landscape size',
    (tester) async {
      await mount(
        tester,
        BoardPresentScreen(board: sampleBoard()),
        width: 640,
        height: 360,
      );
      await tester.ensureVisible(find.byType(VocabularyTile).first);
      await tester.tap(find.byType(VocabularyTile).first);
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsNWidgets(2));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Questions'), findsOneWidget);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -220),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      expect(find.text('Introduction'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('switch scanning selects a highlighted tile with Space', (
    tester,
  ) async {
    AppSettings.switchScanningEnabled.value = true;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: BoardPresentScreen(board: sampleBoard())),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(find.text('Hello'), findsNWidgets(2));
    expect(
      tester
          .widgetList<VocabularyTile>(find.byType(VocabularyTile))
          .first
          .isHighlighted,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    AppSettings.switchScanningEnabled.value = false;
  });
}
