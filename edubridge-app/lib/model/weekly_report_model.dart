// models/weekly_report_model.dart
class WeeklyReport {
  final int id;
  final int childId;
  final String childName;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int lessonsCompleted;
  final int lessonsTotal;
  final int homeworkSubmitted;
  final int homeworkAssigned;
  final int learningSupportMeetingsAttended;
  final int learningSupportMeetingsScheduled;
  final double progressPercentage;
  final String? teacherNotes;
  final String? specialistNotes;
  final String? parentNotes;
  final List<String> achievements;
  final List<String> concerns;
  final DateTime generatedAt;

  WeeklyReport({
    required this.id,
    required this.childId,
    required this.childName,
    required this.weekStart,
    required this.weekEnd,
    required this.lessonsCompleted,
    required this.lessonsTotal,
    required this.homeworkSubmitted,
    required this.homeworkAssigned,
    required this.learningSupportMeetingsAttended,
    required this.learningSupportMeetingsScheduled,
    required this.progressPercentage,
    this.teacherNotes,
    this.specialistNotes,
    this.parentNotes,
    this.achievements = const [],
    this.concerns = const [],
    required this.generatedAt,
  });

  double get homeworkRate => homeworkAssigned == 0
      ? 0
      : homeworkSubmitted / homeworkAssigned;

  double get learningSupportMeetingRate => learningSupportMeetingsScheduled == 0
      ? 0
      : learningSupportMeetingsAttended / learningSupportMeetingsScheduled;

  factory WeeklyReport.fromJson(Map<String, dynamic> json) => WeeklyReport(
        id: json['id'],
        childId: json['child_id'],
        childName: json['child_name'] ?? '',
        weekStart: DateTime.parse(json['week_start']),
        weekEnd: DateTime.parse(json['week_end']),
        lessonsCompleted: json['lessons_completed'] ?? 0,
        lessonsTotal: json['lessons_total'] ?? 0,
        homeworkSubmitted: json['homework_submitted'] ?? 0,
        homeworkAssigned: json['homework_assigned'] ?? 0,
        learningSupportMeetingsAttended: json['learning_support_meetings_attended'] ?? 0,
        learningSupportMeetingsScheduled: json['learning_support_meetings_scheduled'] ?? 0,
        progressPercentage:
            (json['progress_percentage'] ?? 0).toDouble(),
        teacherNotes: json['teacher_notes'],
        specialistNotes: json['specialist_notes'],
        parentNotes: json['parent_notes'],
        achievements:
            List<String>.from(json['achievements'] as List? ?? []),
        concerns: List<String>.from(json['concerns'] as List? ?? []),
        generatedAt: DateTime.parse(json['generated_at']),
      );
}