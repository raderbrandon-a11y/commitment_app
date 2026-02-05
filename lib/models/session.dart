import 'outcomes.dart';

class Session {
  final String id;
  final String task;
  final int durationMinutes;
  final int startTimeMs;
  final int endTimeMs;

  final bool endedEarly;
  final Outcome? outcome;
  final int? loggedAtMs;

  // 🔒 Premium-only (optional)
  final String? category;

  Session({
    required this.id,
    required this.task,
    required this.durationMinutes,
    required this.startTimeMs,
    required this.endTimeMs,
    this.endedEarly = false,
    this.outcome,
    this.loggedAtMs,
    this.category,
  });

  Session copyWith({
    bool? endedEarly,
    Outcome? outcome,
    int? loggedAtMs,
    String? category,
  }) {
    return Session(
      id: id,
      task: task,
      durationMinutes: durationMinutes,
      startTimeMs: startTimeMs,
      endTimeMs: endTimeMs,
      endedEarly: endedEarly ?? this.endedEarly,
      outcome: outcome ?? this.outcome,
      loggedAtMs: loggedAtMs ?? this.loggedAtMs,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'task': task,
        'durationMinutes': durationMinutes,
        'startTimeMs': startTimeMs,
        'endTimeMs': endTimeMs,
        'endedEarly': endedEarly,
        'outcome': outcome?.name,
        'loggedAtMs': loggedAtMs,
        'category': category,
      };

  factory Session.fromJson(Map<String, dynamic> json) {
    final rawOutcome = json['outcome'];
    final parsedOutcome =
        rawOutcome is String ? outcomeFromString(rawOutcome) : null;

    final rawCat = json['category'];
    final cat =
        rawCat is String && rawCat.trim().isNotEmpty ? rawCat.trim() : null;

    return Session(
      id: (json['id'] as String?) ?? '',
      task: (json['task'] as String?) ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      startTimeMs: (json['startTimeMs'] as num?)?.toInt() ?? 0,
      endTimeMs: (json['endTimeMs'] as num?)?.toInt() ?? 0,
      endedEarly: (json['endedEarly'] as bool?) ?? false,
      outcome: parsedOutcome,
      loggedAtMs: (json['loggedAtMs'] as num?)?.toInt(),
      category: cat,
    );
  }
}
