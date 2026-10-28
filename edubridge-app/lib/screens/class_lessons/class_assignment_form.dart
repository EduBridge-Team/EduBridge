import 'package:flutter/material.dart';
import '../../model/class_lessons/class_lesson_assignment.dart';
import '../academics/academic_choice_field.dart';

/// Presentation only. The coordinator rejects callbacks from old option snapshots.
class ClassAssignmentForm extends StatelessWidget {
  const ClassAssignmentForm({super.key, required this.options, required this.enabled,
    required this.lessonId, required this.goalIds, required this.onLesson,
    required this.onGoal, required this.onAdaptation});
  final ClassAssignmentOptions options;
  final bool enabled;
  final int? lessonId;
  final Map<int, int> goalIds;
  final ValueChanged<int> onLesson;
  final void Function(int childId, int goalId) onGoal;
  final void Function(int childId, String text) onAdaptation;
  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    String label(String ar, String en) => english ? en : ar;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AcademicChoiceField(key: const ValueKey('class-assignment-lesson'),
        label: label('الدرس', 'Lesson'), options: options.lessons, value: lessonId,
        requiredMessage: label('اختاري الدرس', 'Choose a lesson'), onChanged: enabled ? onLesson : null),
      if (options.lessons.isEmpty) Text(label('لا توجد دروس متاحة للإسناد.', 'No lessons available to assign.')),
      if (options.students.isEmpty) Text(label('لا يوجد طلاب متاحون في هذه الشعبة.', 'No students available in this section.')),
      for (final student in options.students) Card(child: Padding(padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(student.name, style: Theme.of(context).textTheme.titleMedium),
          AcademicChoiceField(key: ValueKey('class-assignment-goal-${student.id}'),
            label: label('هدف IEP (اختياري)', 'IEP goal (optional)'),
            options: {0: label('بدون ربط بهدف', 'No linked goal'), for (final g in student.goals) g.id: g.title},
            value: goalIds[student.id] ?? 0, requiredMessage: '',
            onChanged: enabled ? (id) => onGoal(student.id, id) : null),
          TextFormField(key: ValueKey('class-assignment-adaptation-${student.id}'),
            enabled: enabled, minLines: 2, maxLines: null, maxLength: 2000,
            decoration: InputDecoration(label: Text(label('تكييف الطالب (اختياري)', 'Student adaptation (optional)'))),
            onChanged: (value) => onAdaptation(student.id, value)),
        ]))),
    ]);
  }
}
