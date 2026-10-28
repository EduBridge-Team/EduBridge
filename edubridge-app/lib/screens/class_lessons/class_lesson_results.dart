import 'package:flutter/material.dart';
import '../../model/class_lessons/class_lesson_catalog.dart';

class ClassLessonResults extends StatelessWidget {
  const ClassLessonResults({super.key, required this.section});
  final ClassLessonSection section;
  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    String label(String ar, String en) => english ? en : ar;
    final states = <String, String>{
      'not_started': label('لم يبدأ', 'Not started'), 'in_progress': label('قيد التقدم', 'In progress'),
      'completed': label('مكتمل', 'Completed'),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (section.lessons.isEmpty) Text(label('لا توجد دروس مسندة لهذه الشعبة.', 'No lessons assigned to this section.')),
      for (final lesson in section.lessons) Card(
        key: ValueKey(('class-lesson', section.id, lesson.id)),
        child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SelectableText(lesson.title, style: Theme.of(context).textTheme.titleLarge),
          if (lesson.students.isEmpty) Text(label('لا توجد بيانات طلاب متاحة لهذا الدرس.', 'No student data available for this lesson.')),
          for (final student in lesson.students) Padding(
            key: ValueKey(('class-student', lesson.id, student.childId)), padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(student.name, style: Theme.of(context).textTheme.titleMedium),
              Text('${label('الحالة', 'Status')}: ${states[student.state] ?? '—'}'),
              Text('${label('النتيجة', 'Result')}: ${student.score == null ? '—' : '${student.score} / ${student.maximum}'}'),
              Text('${label('هدف IEP المرتبط', 'Linked IEP goal')}: ${student.goalTitle ?? '—'}'),
              if (student.adaptation?.trim().isNotEmpty == true) SelectableText(student.adaptation!),
            ])),
        ])),
      ),
    ]);
  }
}
