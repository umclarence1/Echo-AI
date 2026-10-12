import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Caches synthesized speech audio, keyed by text + language, so a phrase
/// spoken once plays back with zero network the next time - the "enhance,
/// never block" half of offline-first for text-to-speech, and the reason a
/// live demo repeating the same handful of phrases doesn't burn through the
/// Khaya call quota again on every tap.
///
/// Disk storage (`dart:io`) doesn't exist on Flutter Web, so every entry is
/// also kept in memory for the life of the page - the part of this cache
/// that actually works on web. Disk storage still runs underneath for
/// native builds, where it survives closing the app.
class SpeechCache {
  static final Map<String, Uint8List> _memory = {};

  static Future<File?> _fileFor(String text, String langCode) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/speech_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      return File('${cacheDir.path}/${_sanitize('$langCode-$text')}.wav');
    } catch (_) {
      return null;
    }
  }

  static String _sanitize(String input) {
    final safe = input.toLowerCase().trim().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return safe.length > 120 ? safe.substring(0, 120) : safe;
  }

  static Future<Uint8List?> read(String text, String langCode) async {
    final key = _sanitize('$langCode-$text');
    final cached = _memory[key];
    if (cached != null) return cached;
    try {
      final file = await _fileFor(text, langCode);
      if (file != null && await file.exists()) {
        final bytes = await file.readAsBytes();
        _memory[key] = bytes;
        return bytes;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> write(
    String text,
    String langCode,
    Uint8List bytes,
  ) async {
    _memory[_sanitize('$langCode-$text')] = bytes;
    try {
      final file = await _fileFor(text, langCode);
      await file?.writeAsBytes(bytes);
    } catch (_) {}
  }
}
