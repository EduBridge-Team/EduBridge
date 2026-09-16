// models/therapy_model.dart
enum TherapySessionType {
  initial,
  followUp,
  crisis,
  family,
  group,
}

enum TherapySessionStatus { scheduled, completed, cancelled, noShow }

class TherapySession {
  final int id;
  final int childId;
  final String childName;
  final int specialistId;
  final String specialistName;
  final TherapySessionType type;
  final TherapySessionStatus status;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final int durationMinutes;
  final String? notes;
  final String? goals;
  final String? recommendations;
  final int? moodRating;
  final List<String> tags;

  TherapySession({
    required this.id,
    required this.childId,
    required this.childName,
    required this.specialistId,
    required this.specialistName,
    required this.type,
    required this.status,
    required this.scheduledAt,
    this.completedAt,
    this.durationMinutes = 45,
    this.notes,
    this.goals,
    this.recommendations,
    this.moodRating,
    this.tags = const [],
  });

  factory TherapySession.fromJson(Map<String, dynamic> json) =>
      TherapySession(
        id: json['id'],
        childId: json['child_id'],
        childName: json['child_name'] ?? '',
        specialistId: json['specialist_id'],
        specialistName: json['specialist_name'] ?? '',
        type: TherapySessionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TherapySessionType.followUp,
        ),
        status: TherapySessionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TherapySessionStatus.scheduled,
        ),
        scheduledAt: DateTime.parse(json['scheduled_at']),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'])
            : null,
        durationMinutes: json['duration_minutes'] ?? 45,
        notes: json['notes'],
        goals: json['goals'],
        recommendations: json['recommendations'],
        moodRating: json['mood_rating'],
        tags: List<String>.from(json['tags'] as List? ?? []),
      );

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'type': type.name,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'notes': notes,
        'goals': goals,
        'recommendations': recommendations,
        'mood_rating': moodRating,
        'tags': tags,
      };
}