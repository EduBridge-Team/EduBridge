// models/learning_support_meeting_model.dart
enum LearningSupportMeetingType {
  learningPlanning,
  followUp,
  parentReview,
  teamReview,
  groupSupport,
}

enum LearningSupportMeetingStatus { scheduled, completed, cancelled, noShow }

class LearningSupportMeeting {
  final int id;
  final int childId;
  final String childName;
  final int specialistId;
  final String specialistName;
  final LearningSupportMeetingType type;
  final LearningSupportMeetingStatus status;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final int durationMinutes;
  final String? notes;
  final String? goals;
  final String? recommendations;
  final int? moodRating;
  final List<String> tags;

  LearningSupportMeeting({
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

  factory LearningSupportMeeting.fromJson(Map<String, dynamic> json) =>
      LearningSupportMeeting(
        id: json['id'],
        childId: json['child_id'],
        childName: json['child_name'] ?? '',
        specialistId: json['specialist_id'],
        specialistName: json['specialist_name'] ?? '',
        type: _typeFromJson(json['type']?.toString()),
        status: LearningSupportMeetingStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => LearningSupportMeetingStatus.scheduled,
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

LearningSupportMeetingType _typeFromJson(String? value) {
  switch (value) {
    case 'learningPlanning':
    case 'initial':
      return LearningSupportMeetingType.learningPlanning;
    case 'parentReview':
    case 'family':
      return LearningSupportMeetingType.parentReview;
    case 'teamReview':
    case 'crisis':
      return LearningSupportMeetingType.teamReview;
    case 'groupSupport':
    case 'group':
      return LearningSupportMeetingType.groupSupport;
    case 'followUp':
    default:
      return LearningSupportMeetingType.followUp;
  }
}
