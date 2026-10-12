import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/context.dart';
import '../models/echo_language.dart';
import '../models/vocabulary_item.dart';
import 'app_settings.dart';

/// Saves what a person builds - People, Favorites, most-used words, their own
/// contexts and their settings - on the device only, so it survives closing
/// the app. Nothing here is ever sent anywhere.
class UserDataStore {
  static SharedPreferences? _prefs;

  static const _kOnboarded = 'onboarded_v1';
  static const _kLanguage = 'language_v1';
  static const _kNaturalSpeech = 'natural_speech_v1';
  static const _kScanning = 'switch_scanning_v1';
  static const _kGender = 'speaker_gender_v1';
  static const _kPeople = 'people_v1';
  static const _kFavorites = 'favorites_v1';
  static const _kUsage = 'usage_counts_v1';
  static const _kContexts = 'custom_contexts_v1';

  /// Call once before runApp: restores settings and keeps them saved.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;

      final code = prefs.getString(_kLanguage);
      final saved = EchoLanguage.all.where((l) => l.code == code);
      if (saved.isNotEmpty) AppSettings.language.value = saved.first;
      AppSettings.naturalSpeechEnabled.value =
          prefs.getBool(_kNaturalSpeech) ?? true;
      AppSettings.switchScanningEnabled.value =
          prefs.getBool(_kScanning) ?? false;
      AppSettings.speakerGender.value =
          prefs.getString(_kGender) ?? 'masculine';
    } catch (e) {
      debugPrint('Could not open saved data: $e');
    }

    AppSettings.language.addListener(
      () => _prefs?.setString(_kLanguage, AppSettings.language.value.code),
    );
    AppSettings.naturalSpeechEnabled.addListener(
      () => _prefs?.setBool(
        _kNaturalSpeech,
        AppSettings.naturalSpeechEnabled.value,
      ),
    );
    AppSettings.switchScanningEnabled.addListener(
      () => _prefs?.setBool(
        _kScanning,
        AppSettings.switchScanningEnabled.value,
      ),
    );
    AppSettings.speakerGender.addListener(
      () => _prefs?.setString(_kGender, AppSettings.speakerGender.value),
    );
  }

  static bool get onboarded => _prefs?.getBool(_kOnboarded) ?? false;
  static Future<void> markOnboarded() async =>
      _prefs?.setBool(_kOnboarded, true);

  // ---- lists of words ----
  static List<VocabularyItem> loadItems(String key) {
    try {
      final raw = _prefs?.getString(key);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => VocabularyItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveItems(String key, List<VocabularyItem> items) async {
    await _prefs?.setString(
      key,
      jsonEncode(items.map((i) => i.toJson()).toList()),
    );
  }

  static List<VocabularyItem> loadPeople() => loadItems(_kPeople);
  static Future<void> savePeople(List<VocabularyItem> v) =>
      _saveItems(_kPeople, v);

  static List<VocabularyItem> loadFavorites() => loadItems(_kFavorites);
  static Future<void> saveFavorites(List<VocabularyItem> v) =>
      _saveItems(_kFavorites, v);

  // ---- most-used words ----
  static Map<String, int> loadUsage() {
    try {
      final raw = _prefs?.getString(_kUsage);
      if (raw == null) return {};
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveUsage(Map<String, int> usage) async =>
      _prefs?.setString(_kUsage, jsonEncode(usage));

  // ---- the person's own contexts ----
  static List<Context> loadCustomContexts() {
    try {
      final raw = _prefs?.getString(_kContexts);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => Context.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomContexts(List<Context> contexts) async =>
      _prefs?.setString(
        _kContexts,
        jsonEncode(contexts.map((c) => c.toJson()).toList()),
      );
}
