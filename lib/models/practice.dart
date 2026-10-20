import 'dart:math';

String practiceId() =>
    '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 30)}';

class PracticeProfile {
  final String id;
  final String name;
  const PracticeProfile({required this.id, required this.name});
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory PracticeProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final name = json['name'] as String;
    if (id.isEmpty || name.trim().isEmpty || name.length > 80) {
      throw const FormatException('Invalid learner');
    }
    return PracticeProfile(id: id, name: name);
  }
}

enum PracticeOutcome { correct, incorrect, skipped }

class PracticeResponse {
  final String promptId;
  final String target;
  final String answer;
  final PracticeOutcome outcome;
  final int elapsedMs;
  const PracticeResponse({
    required this.promptId,
    required this.target,
    required this.answer,
    required this.outcome,
    required this.elapsedMs,
  });
  Map<String, dynamic> toJson() => {
    'promptId': promptId,
    'target': target,
    'answer': answer,
    'outcome': outcome.name,
    'elapsedMs': elapsedMs,
  };
  factory PracticeResponse.fromJson(Map<String, dynamic> json) =>
      PracticeResponse(
        promptId: json['promptId'] as String,
        target: json['target'] as String,
        answer: json['answer'] as String,
        outcome: PracticeOutcome.values.byName(json['outcome'] as String),
        elapsedMs: json['elapsedMs'] as int,
      );
}

class PracticeResult {
  final String id;
  final String profileId;
  final DateTime startedAt;
  final int plannedSeconds;
  final int elapsedMs;
  final bool completed;
  final String deckVersion;
  final List<PracticeResponse> responses;
  PracticeResult({
    required this.id,
    required this.profileId,
    required this.startedAt,
    required this.plannedSeconds,
    required this.elapsedMs,
    required this.completed,
    required this.deckVersion,
    required List<PracticeResponse> responses,
  }) : responses = List.unmodifiable(responses) {
    if (id.isEmpty ||
        profileId.isEmpty ||
        plannedSeconds <= 0 ||
        elapsedMs <= 0 ||
        elapsedMs > plannedSeconds * 1000 ||
        (completed && elapsedMs != plannedSeconds * 1000) ||
        responses.any(
          (r) =>
              r.elapsedMs < 0 ||
              r.elapsedMs >= plannedSeconds * 1000 ||
              r.elapsedMs > elapsedMs,
        )) {
      throw const FormatException('Invalid practice result');
    }
  }
  int get sentences =>
      responses.where((r) => r.outcome == PracticeOutcome.correct).length;
  int get incorrect =>
      responses.where((r) => r.outcome == PracticeOutcome.incorrect).length;
  int get skipped =>
      responses.where((r) => r.outcome == PracticeOutcome.skipped).length;
  int get attempts => sentences + incorrect;
  double get sentencesPerMinute => sentences * 60000 / elapsedMs;
  double? get accuracy => attempts == 0 ? null : sentences / attempts;
  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'plannedSeconds': plannedSeconds,
    'elapsedMs': elapsedMs,
    'completed': completed,
    'deckVersion': deckVersion,
    'responses': responses.map((r) => r.toJson()).toList(),
  };
  factory PracticeResult.fromJson(Map<String, dynamic> json) => PracticeResult(
    id: json['id'] as String,
    profileId: json['profileId'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    plannedSeconds: json['plannedSeconds'] as int,
    elapsedMs: json['elapsedMs'] as int,
    completed: json['completed'] as bool,
    deckVersion: json['deckVersion'] as String,
    responses: (json['responses'] as List)
        .map(
          (r) => PracticeResponse.fromJson(Map<String, dynamic>.from(r as Map)),
        )
        .toList(),
  );
}

class PracticeData {
  final List<PracticeProfile> profiles;
  final List<PracticeResult> results;
  final String selectedProfileId;
  PracticeData({
    required List<PracticeProfile> profiles,
    required List<PracticeResult> results,
    required this.selectedProfileId,
  }) : profiles = List.unmodifiable(profiles),
       results = List.unmodifiable(results) {
    final ids = profiles.map((p) => p.id).toSet();
    if (profiles.any(
          (p) => p.id.isEmpty || p.name.trim().isEmpty || p.name.length > 80,
        ) ||
        ids.length != profiles.length ||
        !ids.contains(selectedProfileId) ||
        results.any((r) => !ids.contains(r.profileId)) ||
        results.map((r) => r.id).toSet().length != results.length) {
      throw const FormatException('Invalid practice data');
    }
  }
  factory PracticeData.empty() => PracticeData(
    profiles: [const PracticeProfile(id: 'local', name: 'You')],
    results: [],
    selectedProfileId: 'local',
  );
  PracticeProfile get selectedProfile =>
      profiles.firstWhere((p) => p.id == selectedProfileId);
  PracticeData copyWith({
    List<PracticeProfile>? profiles,
    List<PracticeResult>? results,
    String? selectedProfileId,
  }) => PracticeData(
    profiles: profiles ?? this.profiles,
    results: results ?? this.results,
    selectedProfileId: selectedProfileId ?? this.selectedProfileId,
  );
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'selectedProfileId': selectedProfileId,
    'profiles': profiles.map((p) => p.toJson()).toList(),
    'results': results.map((r) => r.toJson()).toList(),
  };
  factory PracticeData.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported practice data');
    }
    return PracticeData(
      selectedProfileId: json['selectedProfileId'] as String,
      profiles: (json['profiles'] as List)
          .map(
            (p) =>
                PracticeProfile.fromJson(Map<String, dynamic>.from(p as Map)),
          )
          .toList(),
      results: (json['results'] as List)
          .map(
            (r) => PracticeResult.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList(),
    );
  }
}
