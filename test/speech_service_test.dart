import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echo_aac/models/echo_language.dart';
import 'package:echo_aac/services/speech_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Stop cancels a message while its device voice is still preparing',
    () async {
      final availabilityRequested = Completer<void>();
      final availabilityResult = Completer<bool>();
      final spoken = <String>[];
      const channel = MethodChannel('flutter_tts');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'isLanguageAvailable') {
              availabilityRequested.complete();
              return availabilityResult.future;
            }
            if (call.method == 'speak') spoken.add(call.arguments.toString());
            return 1;
          });
      final speech = SpeechService();
      try {
        final pending = speech.speak('Hello', EchoLanguage.english);
        await availabilityRequested.future;
        await speech.stop();
        availabilityResult.complete(true);
        expect(await pending, isFalse);
        expect(spoken, isEmpty);
      } finally {
        await speech.dispose();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );
}
