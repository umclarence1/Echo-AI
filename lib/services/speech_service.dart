import 'package:audioplayers/audioplayers.dart';
import '../models/echo_language.dart';
import 'device_voice.dart';
import 'khaya_service.dart';
import 'speech_cache.dart';

/// Shared playback for the communication board and prepared presentations.
/// A stop invalidates in-flight synthesis, so late responses cannot play.
class SpeechService {
  AudioPlayer? _player;
  int _generation = 0;
  bool _disposed = false;

  Future<void> stop() async {
    _generation++;
    await _stopPlayback();
  }

  Future<void> _stopPlayback() async {
    try {
      await Future.wait([
        if (_player != null) _player!.stop(),
        DeviceVoice.stop(),
      ]);
    } catch (_) {
      // Device/plugin teardown must not prevent leaving a screen.
    }
  }

  Future<bool> speak(String text, EchoLanguage language) async {
    if (_disposed || text.trim().isEmpty) return false;
    final generation = ++_generation;
    try {
      await _stopPlayback();
      if (_disposed || generation != _generation) return false;
      if (language.prefersKhayaVoice) {
        var audio = await SpeechCache.read(text, language.code);
        if (_disposed || generation != _generation) return false;
        if (audio == null) {
          audio = await KhayaService.synthesizeSpeech(
            text,
            language.khayaCode!,
          );
          if (_disposed || generation != _generation) return false;
          if (audio != null) {
            await SpeechCache.write(text, language.code, audio);
          }
        }
        if (_disposed || generation != _generation) return false;
        if (audio != null) {
          final player = _player ??= AudioPlayer();
          await player.play(BytesSource(audio));
          return true;
        }
      }
      if (_disposed || generation != _generation) return false;
      return language.voiceLocale != null &&
          await DeviceVoice.speak(
            text,
            language.voiceLocale!,
            isCancelled: () => _disposed || generation != _generation,
          );
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _player?.dispose();
  }
}
