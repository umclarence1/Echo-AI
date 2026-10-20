import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/practice.dart';

/// Practice has its own storage key. Failed reads never become an empty write.
class PracticeRepository {
  static const storageKey = 'practice_v1';
  static Future<void>? _pending;

  Future<PracticeData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    return raw == null
        ? PracticeData.empty()
        : PracticeData.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          );
  }

  Future<void> _update(PracticeData Function(PracticeData) change) async {
    final previous = _pending;
    final lock = Completer<void>();
    _pending = lock.future;
    try {
      if (previous != null) await previous;
      final data = change(await load());
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(storageKey, jsonEncode(data.toJson()))) {
        throw StateError('Could not save practice data');
      }
    } finally {
      lock.complete();
      if (identical(_pending, lock.future)) _pending = null;
    }
  }

  Future<void> addProfile(PracticeProfile profile) => _update((data) {
    if (profile.name.trim().isEmpty ||
        profile.name.length > 80 ||
        data.profiles.any(
          (p) => p.name.toLowerCase() == profile.name.trim().toLowerCase(),
        )) {
      throw const FormatException('Choose a different learner name');
    }
    return data.copyWith(
      profiles: [...data.profiles, profile],
      selectedProfileId: profile.id,
    );
  });
  Future<void> selectProfile(String id) =>
      _update((data) => data.copyWith(selectedProfileId: id));
  Future<void> saveResult(PracticeResult result) => _update(
    (data) => data.copyWith(
      results: [...data.results.where((r) => r.id != result.id), result],
    ),
  );
  Future<void> clearHistory(String profileId) => _update(
    (data) => data.copyWith(
      results: data.results.where((r) => r.profileId != profileId).toList(),
    ),
  );
}
