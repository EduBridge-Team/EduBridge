import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/teacher_assignment.dart';
import '../../model/schools/teacher_assignments_catalog.dart';

class TeacherAssignmentCard extends StatelessWidget {
  const TeacherAssignmentCard({
    super.key,
    required this.assignment,
    required this.catalog,
    required this.onRemove,
  });
  final TeacherAssignment assignment;
  final TeacherAssignmentsCatalog catalog;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) {
    final teacher = catalog.teachers.firstWhere(
      (v) => v.id == assignment.teacherId,
    );
    final subject = catalog.subjects.firstWhere(
      (v) => v.id == assignment.subjectId,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(teacher.name),
            Text(catalog.sectionLabel(assignment.sectionId)),
            Text(subject.name),
            TextButton(
              key: ValueKey('assignment-remove-${assignment.id}'),
              onPressed: onRemove,
              child: Text(context.l10n.teacherAssignmentRemove),
            ),
          ],
        ),
      ),
    );
  }
}
