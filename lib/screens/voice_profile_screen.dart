import 'package:flutter/material.dart';
import '../services/language_scope.dart';

/// Lets a user revisit voice profile setup from the main menu, distinct
/// from the one-time onboarding screen shown at first launch.
class VoiceProfileScreen extends StatelessWidget {
  const VoiceProfileScreen({super.key});

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('voice_cloning')),
        content: Text(context.tr('voice_soon')),
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
      appBar: AppBar(title: Text(context.tr('voice_profile_title'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mic_none, size: 48, color: Colors.blueGrey),
            const SizedBox(height: 16),
            Text(
              context.tr('voice_profile_none'),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showComingSoon(context),
              child: Text(context.tr('record_samples')),
            ),
          ],
        ),
      ),
    );
  }
}
