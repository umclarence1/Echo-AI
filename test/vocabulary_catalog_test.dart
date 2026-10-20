import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo_aac/data/core_vocabulary.dart';
import 'package:echo_aac/data/context_data.dart';
import 'package:echo_aac/data/collections_data.dart';
import 'package:echo_aac/data/library_vocabulary.dart';
import 'package:echo_aac/models/echo_language.dart';
import 'package:echo_aac/models/vocabulary_item.dart';
import 'package:echo_aac/screens/library_screen.dart';
import 'package:echo_aac/screens/communication_board.dart';
import 'package:echo_aac/services/app_settings.dart';
import 'package:echo_aac/services/user_data_store.dart';
import 'package:echo_aac/services/vocabulary_catalog.dart';
import 'package:echo_aac/widgets/vocabulary_grid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Set<String> labels(Iterable<VocabularyItem> items) =>
      items.map((i) => i.label).toSet();

  test(
    'All Words includes every source exactly once and every word has a category',
    () {
      final all = VocabularyCatalog.items;
      final source = {
        for (final item in CoreVocabulary.getItems()) item.label,
        for (final c in ContextData.getContexts())
          for (final i in c.vocabulary) i.label,
        for (final c in CollectionsData.getCollections())
          for (final i in c.items) i.label,
        for (final c in LibraryVocabulary.categories)
          for (final i in c.words) i.label,
        'feel',
      };
      expect(labels(all), source);
      expect(all.map((i) => i.label.toLowerCase()).toSet().length, all.length);
      expect(all.map((i) => i.id).toSet().length, all.length);
      expect(labels(LibraryScreen.allItems), source);
      for (final item in all) {
        expect(
          VocabularyCatalog.categories.any(
            (c) => VocabularyCatalog.belongsTo(item, c.id),
          ),
          true,
          reason: item.label,
        );
      }
    },
  );

  test(
    'every quick group contains its full library category and keeps original shortcuts first',
    () {
      final groups = VocabularyCatalog.collections;
      const categoryFor = {
        'collection_feel': 'feelings',
        'collection_food': 'food_drink',
        'collection_places': 'places',
      };
      for (final category in VocabularyCatalog.categories.where(
        (c) => c.id != 'people' && c.id != 'core',
      )) {
        final group = groups.firstWhere(
          (g) =>
              (categoryFor[g.id] ?? g.id.replaceFirst('collection_', '')) ==
              category.id,
        );
        expect(
          labels(group.items),
          labels(category.items),
          reason: category.label,
        );
      }
      for (final seed in CollectionsData.getCollections()) {
        final group = groups.firstWhere((g) => g.id == seed.id);
        expect(
          group.items.take(seed.items.length).map((i) => i.label),
          seed.items.map((i) => i.label),
        );
      }
      final food = groups.firstWhere((c) => c.id == 'collection_food');
      expect(
        labels(food.items),
        containsAll(['Rice', 'Water', 'Fufu', 'Apple', 'Milk', 'Pasta']),
      );
      expect(
        labels(groups.firstWhere((c) => c.id == 'collection_feel').items),
        containsAll(['Happy', 'Worried', 'Hungry']),
      );
      expect(
        labels(groups.firstWhere((c) => c.id == 'collection_places').items),
        containsAll(['School', 'Airport']),
      );
    },
  );

  test(
    'contexts include related categories and cross-category words stay discoverable',
    () {
      for (final seed in ContextData.getContexts()) {
        final context = VocabularyCatalog.contexts.firstWhere(
          (c) => c.id == seed.id,
        );
        expect(
          context.vocabulary.take(seed.vocabulary.length).map((i) => i.label),
          seed.vocabulary.map((i) => i.label),
        );
        expect(
          labels(
            VocabularyCatalog.items,
          ).containsAll(labels(context.vocabulary)),
          true,
        );
      }
      for (final pair in [
        ('Jeans', 'clothes'),
        ('Laptop', 'technology'),
        ('Pencil', 'school_fun'),
        ('Doctor', 'people'),
        ('Doctor', 'body_health'),
        ('Fufu', 'food_drink'),
        ('I', 'core'),
      ]) {
        expect(
          labels(VocabularyCatalog.categoryItems(pair.$2)),
          contains(pair.$1),
        );
      }
      expect(
        labels(
          VocabularyCatalog.contexts
              .firstWhere((c) => c.id == 'context_school')
              .vocabulary,
        ),
        contains('Notebook'),
      );
      expect(
        labels(
          VocabularyCatalog.contexts
              .firstWhere((c) => c.id == 'context_hospital')
              .vocabulary,
        ),
        contains('Bandage'),
      );
    },
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppSettings.language.value = EchoLanguage.english;
    AppSettings.switchScanningEnabled.value = false;
    await UserDataStore.init();
  });
  Future<void> mount(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  Widget library({List<VocabularyItem>? items}) => LibraryScreen(
    items: items ?? LibraryScreen.allItems,
    categoryName: (s) => s,
    labelBuilder: (i) => i.label,
    secondaryLabelBuilder: (_) => null,
    onItemTap: (_) {},
  );
  Future<void> category(
    WidgetTester tester,
    String id, {
    double delta = 180,
  }) async {
    final chip = find.byKey(ValueKey('library_category_$id'));
    final scroll = find.descendant(
      of: find.byKey(const ValueKey('library_categories')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(chip, delta, scrollable: scroll);
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(chip).selected, true);
  }

  Finder tile(String label) => find.byWidgetPredicate(
    (w) => w is VocabularyTile && w.item.label == label,
  );

  testWidgets(
    'library finds built-in foods and applies search inside the selected category',
    (tester) async {
      await mount(tester, library());
      await tester.enterText(find.byType(TextField), 'fufu');
      await tester.pumpAndSettle();
      expect(tile('Fufu'), findsOneWidget);
      await category(tester, 'food_drink');
      expect(tile('Fufu'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'milk');
      await tester.pumpAndSettle();
      expect(tile('Milk'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'doctor');
      await tester.pumpAndSettle();
      expect(tile('Doctor'), findsNothing);
      final all = find.byKey(const ValueKey('library_category_all'));
      final scroll = find.descendant(
        of: find.byKey(const ValueKey('library_categories')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(all, -180, scrollable: scroll);
      await tester.ensureVisible(all);
      await tester.pumpAndSettle();
      await tester.tap(all);
      await tester.pumpAndSettle();
      expect(tile('Doctor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('personal words remain available alongside built-in words', (
    tester,
  ) async {
    final person = VocabularyItem(id: 'person_sam', label: 'Sam');
    await mount(tester, library(items: [...LibraryScreen.allItems, person]));
    await tester.enterText(find.byType(TextField), 'Sam');
    await tester.pumpAndSettle();
    expect(tile('Sam'), findsOneWidget);
    await category(tester, 'personal');
    expect(tile('Sam'), findsOneWidget);
    await category(tester, 'people', delta: -180);
    expect(tile('Sam'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'board food and feeling groups include library words with correct insertion',
    (tester) async {
      await mount(tester, const CommunicationBoard());
      await tester.tap(tile('I').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('collection_feel')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(tile('Worried'));
      await tester.tap(tile('Worried'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'I feel Worried',
      );
      await tester.tap(find.text('Clear').first);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('board_collections')),
        const Offset(-140, 0),
      );
      await tester.pumpAndSettle();
      final food = find.byKey(const ValueKey('collection_food'));
      await tester.ensureVisible(food);
      await tester.tap(food);
      await tester.pumpAndSettle();
      await tester.ensureVisible(tile('Apple'));
      await tester.tap(tile('Apple'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Apple',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
