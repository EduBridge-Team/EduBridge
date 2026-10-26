import '../enrollment/enrollment_models.dart';
import '../schools/teacher_assignment.dart';
import 'institution_academic_records.dart';

class InstitutionTeacherAssignment {
  const InstitutionTeacherAssignment(this.id, this.draft, this.teacherName);
  final int id;
  final TeacherAssignmentDraft draft;
  final String teacherName;
}

/// Teachers are active institution members, not fabricated school memberships.
class InstitutionTeacherAssignments {
  InstitutionTeacherAssignments._(this.academic, this.teachers, this.assignments);
  final InstitutionAcademicRecords academic;
  final Map<int, String> teachers;
  final List<InstitutionTeacherAssignment> assignments;

  factory InstitutionTeacherAssignments.fromJson(
    InstitutionAcademicRecords academic,
    Map<String, dynamic> data,
  ) {
    final teachers = <int, String>{};
    for (final raw in enrollmentList(data['teachers'])) {
      final item = enrollmentMap(raw);
      final id = enrollmentId(item['id']);
      if (teachers.containsKey(id)) throw const FormatException('Duplicate teacher');
      teachers[id] = enrollmentText(item['name']);
    }
    final assignments = <InstitutionTeacherAssignment>[];
    final ids = <int>{}, identities = <String>{};
    for (final raw in enrollmentList(data['teacher_assignments'])) {
      final item = enrollmentMap(raw);
      final id = enrollmentId(item['id']);
      final draft = TeacherAssignmentDraft(
        teacherId: enrollmentId(item['teacher_id']),
        sectionId: enrollmentId(item['section_id']),
        subjectId: enrollmentId(item['subject_id']),
      );
      if (!ids.add(id) || !identities.add(draft.identity) ||
          !academic.sections.any((v) => v.id == draft.sectionId) ||
          !academic.curriculum.subjects.any((v) => v.id == draft.subjectId)) {
        throw const FormatException('Invalid assignment relationships');
      }
      // Historical assignments can outlive active institution membership.
      assignments.add(InstitutionTeacherAssignment(
        id, draft, enrollmentText(item['teacher_name']),
      ));
    }
    return InstitutionTeacherAssignments._(
      academic, Map.unmodifiable(teachers), List.unmodifiable(assignments),
    );
  }

  bool canCreate(TeacherAssignmentDraft draft) => draft.valid &&
      teachers.containsKey(draft.teacherId) &&
      academic.sections.any((v) => v.id == draft.sectionId) &&
      academic.curriculum.subjects.any((v) => v.id == draft.subjectId && v.active) &&
      !assignments.any((v) => v.draft.identity == draft.identity);

  String sectionLabel(int id) {
    final section = academic.sections.firstWhere((v) => v.id == id);
    final year = academic.years.firstWhere((v) => v.id == section.yearId);
    final grade = academic.grades.firstWhere((v) => v.id == section.gradeId);
    return '${year.name} — ${grade.name} — ${section.name}';
  }
}
