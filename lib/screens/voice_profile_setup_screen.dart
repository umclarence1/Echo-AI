import 'package:flutter/material.dart';
import '../services/language_scope.dart';
import '../services/user_data_store.dart';
import 'communication_board.dart';

class VoiceProfileSetupScreen extends StatelessWidget {
  const VoiceProfileSetupScreen({super.key});

  Future<void> _continueToBoard(BuildContext context) async {
    await UserDataStore.markOnboarded();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CommunicationBoard()),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('voice_cloning')),
        content: Text(context.tr('voice_soon_onboarding')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr('got_it')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mic, size: 56, color: Colors.blueGrey),
              const SizedBox(height: 16),
              Text(
                context.tr('voice_question'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('voice_optional'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _showComingSoon(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(context.tr('record_samples')),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _continueToBoard(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(context.tr('skip_for_now')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
