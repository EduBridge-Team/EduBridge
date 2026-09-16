// models/plan_evaluation_model.dart
class PlanEvaluation {
  final int id;
  final int childId;
  final String childName;
  final int planId;
  final int specialistId;
  final String specialistName;
  final bool isPlanAppropriate;
  final String? notesForTeacher;
  final List<String> recommendedChanges;
  final DateTime evaluatedAt;

  PlanEvaluation({
    required this.id,
    required this.childId,
    required this.childName,
    required this.planId,
    required this.specialistId,
    required this.specialistName,
    required this.isPlanAppropriate,
    this.notesForTeacher,
    this.recommendedChanges = const [],
    required this.evaluatedAt,
  });

  factory PlanEvaluation.fromJson(Map<String, dynamic> json) =>
      PlanEvaluation(
        id: json['id'],
        childId: json['child_id'],
        childName: json['child_name'] ?? '',
        planId: json['plan_id'],
        specialistId: json['specialist_id'],
        specialistName: json['specialist_name'] ?? '',
        isPlanAppropriate: json['is_plan_appropriate'] ?? false,
        notesForTeacher: json['notes_for_teacher'],
        recommendedChanges: List<String>.from(
            json['recommended_changes'] as List? ?? []),
        evaluatedAt: DateTime.parse(json['evaluated_at']),
      );

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'plan_id': planId,
        'is_plan_appropriate': isPlanAppropriate,
        'notes_for_teacher': notesForTeacher,
        'recommended_changes': recommendedChanges,
      };
}