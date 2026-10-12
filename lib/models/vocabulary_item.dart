class VocabularyItem {
  final String id;
  final String label;
  final String? symbolUrl;
  final bool isCore;
  final int? position;
  final String? collectionId;
  final List<String>? contexts;
  // Used by the People collection to remember how this person relates to
  // the user, so Natural Speech can offer "He is my brother" alongside
  // the raw "He is Brandon" selection.
  final String? relationship;

  VocabularyItem({
    required this.id,
    required this.label,
    this.symbolUrl,
    this.isCore = false,
    this.position,
    this.collectionId,
    this.contexts,
    this.relationship,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as String,
      label: json['label'] as String,
      symbolUrl: json['symbolUrl'] as String?,
      isCore: json['isCore'] as bool? ?? false,
      position: json['position'] as int?,
      collectionId: json['collectionId'] as String?,
      contexts: (json['contexts'] as List<dynamic>?)?.cast<String>(),
      relationship: json['relationship'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'symbolUrl': symbolUrl,
      'isCore': isCore,
      'position': position,
      'collectionId': collectionId,
      'contexts': contexts,
      'relationship': relationship,
    };
  }

  VocabularyItem copyWith({
    String? id,
    String? label,
    String? symbolUrl,
    bool? isCore,
    int? position,
    String? collectionId,
    List<String>? contexts,
    String? relationship,
  }) {
    return VocabularyItem(
      id: id ?? this.id,
      label: label ?? this.label,
      symbolUrl: symbolUrl ?? this.symbolUrl,
      isCore: isCore ?? this.isCore,
      position: position ?? this.position,
      collectionId: collectionId ?? this.collectionId,
      contexts: contexts ?? this.contexts,
      relationship: relationship ?? this.relationship,
    );
  }
}
