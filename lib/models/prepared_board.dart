import 'vocabulary_item.dart';

/// A saved board is independent of the fixed core vocabulary and contexts.
/// Items keep their original IDs, labels and symbols as a durable fallback.
class BoardSection {
  final String id;
  final String title;
  final List<VocabularyItem> items;

  BoardSection({
    required this.id,
    required this.title,
    required List<VocabularyItem> items,
  }) : items = List.unmodifiable(items);

  BoardSection copyWith({String? title, List<VocabularyItem>? items}) =>
      BoardSection(
        id: id,
        title: title ?? this.title,
        items: items ?? this.items,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory BoardSection.fromJson(Map<String, dynamic> json) => BoardSection(
    id: json['id'] as String,
    title: json['title'] as String,
    items: (json['items'] as List)
        .map(
          (i) => VocabularyItem.fromJson(Map<String, dynamic>.from(i as Map)),
        )
        .toList(),
  );
}

class PreparedBoard {
  final String id;
  final String title;
  final List<BoardSection> sections;
  final DateTime createdAt;
  final DateTime updatedAt;

  PreparedBoard({
    required this.id,
    required this.title,
    required List<BoardSection> sections,
    required this.createdAt,
    required this.updatedAt,
  }) : sections = List.unmodifiable(sections);

  static int _sequence = 0;
  static String newId() =>
      'board_${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';

  PreparedBoard copyWith({String? title, List<BoardSection>? sections}) =>
      PreparedBoard(
        id: id,
        title: title ?? this.title,
        sections: sections ?? this.sections,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  PreparedBoard duplicate(String title) {
    final now = DateTime.now();
    return PreparedBoard(
      id: newId(),
      title: title,
      createdAt: now,
      updatedAt: now,
      sections: [
        for (final section in sections)
          BoardSection(id: newId(), title: section.title, items: section.items),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'sections': sections.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PreparedBoard.fromJson(Map<String, dynamic> json) => PreparedBoard(
    id: json['id'] as String,
    title: json['title'] as String,
    sections: (json['sections'] as List)
        .map((s) => BoardSection.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
