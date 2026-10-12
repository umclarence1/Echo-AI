import 'vocabulary_item.dart';

class Context {
  final String id;
  final String label;
  final String? symbolUrl;
  final List<VocabularyItem> vocabulary;

  Context({
    required this.id,
    required this.label,
    this.symbolUrl,
    required this.vocabulary,
  });

  factory Context.fromJson(Map<String, dynamic> json) {
    return Context(
      id: json['id'] as String,
      label: json['label'] as String,
      symbolUrl: json['symbolUrl'] as String?,
      vocabulary:
          (json['vocabulary'] as List<dynamic>?)
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
      'vocabulary': vocabulary.map((item) => item.toJson()).toList(),
    };
  }
}
