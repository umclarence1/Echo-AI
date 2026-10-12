import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:echo_aac/main.dart';
import 'package:echo_aac/models/echo_language.dart';
import 'package:echo_aac/services/app_settings.dart';
import 'package:echo_aac/services/user_data_store.dart';

/// Drives the real app on a phone-sized screen, offline, the way a person
/// would: onboarding, the board, the word library, emergency phrases.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppSettings.language.value = EchoLanguage.english;
    await UserDataStore.init();
  });

  Future<void> useScreen(WidgetTester tester, double w, double h) async {
    tester.view.physicalSize = Size(w * 3, h * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> reachBoard(WidgetTester tester, String language) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(language));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OutlinedButton).last);
    await tester.pumpAndSettle();
  }

  for (final size in [(360.0, 800.0), (412.0, 915.0)]) {
    testWidgets('board works on a ${size.$1.toInt()}x${size.$2.toInt()} phone',
        (tester) async {
      await useScreen(tester, size.$1, size.$2);
      await reachBoard(tester, 'English');

      expect(find.text('Speak'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tap a core tile and see it in the message.
      await tester.tap(find.text('Help').first);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Help'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('French board, word library and emergency phrases', (tester) async {
    await useScreen(tester, 360, 800);
    await reachBoard(tester, 'Français');

    // The whole board switched language.
    expect(find.text('Parler'), findsOneWidget);
    expect(find.text('Urgence'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Search the word library and add a word.
    await tester.tap(find.text('Mots'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'apple');
    await tester.pumpAndSettle();
    expect(find.text('Pomme'), findsWidgets);
    await tester.tap(find.text('Pomme').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Pomme'), findsOneWidget);

    // Emergency phrases open and show French.
    await tester.tap(find.text('Urgence'));
    await tester.pumpAndSettle();
    expect(find.text("J'ai besoin d'aide."), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final name in ['Ewe', 'Dagbani']) {
    testWidgets('$name can be chosen and opens the board', (tester) async {
      await useScreen(tester, 360, 800);
      await reachBoard(tester, name);
      expect(find.text('Speak'), findsOneWidget);
      expect(AppSettings.language.value.label, name);
      expect(tester.takeException(), isNull);
    });
  }
}
