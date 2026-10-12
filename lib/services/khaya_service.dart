import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/khaya_config.dart';

/// Wraps the Khaya AI (GhanaNLP) translation and text-to-speech APIs.
class KhayaService {
  static const String _baseUrl = 'https://translation-api.ghananlp.org';

  static Map<String, String> get _headers => {
    'Ocp-Apim-Subscription-Key': KhayaConfig.apiKey,
    'Content-Type': 'application/json',
  };

  /// Translates [text] from English to the given target language code
  /// (e.g. "tw" for Twi, "gaa" for Ga). Returns null on failure.
  static Future<String?> translateFromEnglish(
    String text,
    String targetLangCode,
  ) async {
    if (text.trim().isEmpty) return text;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/v1/translate'),
            headers: _headers,
            body: json.encode({'in': text, 'lang': 'en-$targetLangCode'}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _tidyLabel(text, json.decode(response.body) as String, targetLangCode);
      }
      debugPrint('Khaya translate failed (${response.statusCode}): ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Khaya translate error: $e');
      return null;
    }
  }

  /// Khaya sometimes treats a single word as a sentence: it adds a full stop
  /// (Dagbani) or returns a long phrase. For short labels, drop the full stop
  /// and refuse a result that is clearly not a word or short phrase, so the
  /// tile keeps its English label instead of showing nonsense.
  static String? _tidyLabel(String english, String result, String lang) {
    if (english.trim().split(RegExp(r'\s+')).length > 3) return result;
    var text = result.trim();
    if (lang == 'dag') text = text.replaceAll(RegExp(r'\.+$'), '').trim();
    final tooLong = text.split(RegExp(r'\s+')).length > 3;
    final shouting = text.length > 3 && text == text.toUpperCase() && text != text.toLowerCase();
    if (text.isEmpty || tooLong || shouting) return null;
    return text;
  }

  /// Synthesizes speech for [text] in the given language code and returns
  /// the raw WAV audio bytes, or null on failure.
  static Future<Uint8List?> synthesizeSpeech(
    String text,
    String langCode,
  ) async {
    if (text.trim().isEmpty) return null;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/tts/v1/synthesize'),
            headers: _headers,
            body: json.encode({'text': text, 'language': langCode}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      debugPrint('Khaya TTS failed (${response.statusCode}): ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Khaya TTS error: $e');
      return null;
    }
  }
}
