import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Speaks with the phone's built-in text-to-speech voice. Free, works with no
/// internet, and needs no Khaya quota - the offline half of speech output.
class DeviceVoice {
  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;

  static Future<void> _init() async {
    if (_ready) return;
    await _tts.awaitSpeakCompletion(true);
    _ready = true;
  }

  /// A browser loads its voice list in the background after the page opens;
  /// asking too early can wrongly report a language as unavailable. Retries
  /// a few times before giving up, so a fresh page load doesn't cost a
  /// language its voice.
  static Future<bool> _isAvailable(String locale) async {
    for (var attempt = 0; attempt < 4; attempt++) {
      final available = await _tts.isLanguageAvailable(locale);
      if (available == true || available == 1) return true;
      if (attempt < 3) await Future.delayed(const Duration(milliseconds: 400));
    }
    return false;
  }

  /// Returns true if the phone had a voice for [locale] and spoke [text].
  /// Returns false if the voice is missing or speech failed, so the caller
  /// can tell the user how to install it.
  static Future<bool> speak(String text, String locale) async {
    try {
      await _init();
      // Clear anything left over from a previous, possibly-stuck utterance
      // before checking or speaking, so two languages never overlap.
      await _tts.stop();
      if (!await _isAvailable(locale)) return false;
      await _tts.setLanguage(locale);
      // awaitSpeakCompletion can hang forever if the browser's "finished"
      // event never fires (a known flutter_tts-on-web issue, e.g. after the
      // tab loses focus). A stuck wait would silently break every Speak tap
      // after it, since the caller never gets control back. Time it out.
      await _tts.speak(text).timeout(
        const Duration(seconds: 12),
        onTimeout: () => 1,
      );
      return true;
    } catch (e) {
      debugPrint('Device voice error: $e');
      return false;
    }
  }

  /// Silences the phone's voice immediately, so switching to a Khaya-voiced
  /// language never overlaps with a browser utterance still finishing.
  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('Device voice stop error: $e');
    }
  }
}
