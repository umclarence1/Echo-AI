import 'vocabulary_item.dart';

class Collection {
  final String id;
  final String label;
  final String? symbolUrl;
  final List<VocabularyItem> items;

  Collection({
    required this.id,
    required this.label,
    this.symbolUrl,
    required this.items,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      label: json['label'] as String,
      symbolUrl: json['symbolUrl'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => VocabularyItem.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'symbolUrl': symbolUrl,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
