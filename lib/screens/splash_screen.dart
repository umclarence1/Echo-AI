import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/language_scope.dart';
import '../services/user_data_store.dart';
import 'communication_board.dart';
import 'language_selection_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _continue(BuildContext context) {
    // Someone who already chose a language goes straight to their board -
    // except on the web build, which always starts at language choice.
    // There's no installed "app" to reopen on the web, so every visit
    // (including a demo's hard refresh) should show the full flow again,
    // the way a first-time visitor would see it.
    final next = (UserDataStore.onboarded && !kIsWeb)
        ? const CommunicationBoard()
        : const LanguageSelectionScreen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade600,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Echo',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  context.tr('tagline'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => _continue(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
                child: Text(context.tr('get_started')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
