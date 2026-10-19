import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prepared_board.dart';

/// Separate storage key: changes to boards cannot replace favorites/contexts.
/// Invalid or unsupported data is reported, never silently overwritten.
class BoardRepository {
  static const storageKey = 'prepared_boards_v1';

  Future<List<PreparedBoard>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return [];
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported board data');
    }
    return (json['boards'] as List)
        .map((b) => PreparedBoard.fromJson(Map<String, dynamic>.from(b as Map)))
        .toList();
  }

  Future<void> _write(List<PreparedBoard> boards) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      storageKey,
      jsonEncode({
        'schemaVersion': 1,
        'boards': boards.map((b) => b.toJson()).toList(),
      }),
    );
    if (!saved) throw StateError('Could not save boards');
  }

  Future<void> save(PreparedBoard board) async {
    final boards = await load();
    final index = boards.indexWhere((b) => b.id == board.id);
    if (index < 0) {
      boards.add(board);
    } else {
      boards[index] = board;
    }
    await _write(boards);
  }

  Future<void> delete(String id) async {
    final boards = await load();
    boards.removeWhere((b) => b.id == id);
    await _write(boards);
  }
}
