import '../enrollment/enrollment_models.dart';
import 'academic_catalog.dart';
import 'curriculum_catalog.dart';
import 'teacher_assignment.dart';

class TeacherAssignmentsCatalog {
  TeacherAssignmentsCatalog._(
    this.academic,
    List<SchoolTeacher> teachers,
    List<CurriculumSubject> subjects,
    List<TeacherAssignment> assignments,
  ) : teachers = List.unmodifiable(teachers),
      subjects = List.unmodifiable(subjects),
      assignments = List.unmodifiable(assignments);
  final AcademicCatalog academic;
  final List<SchoolTeacher> teachers;
  final List<CurriculumSubject> subjects;
  final List<TeacherAssignment> assignments;
  int get schoolId => academic.school.id;
  factory TeacherAssignmentsCatalog.fromJson(Map<String, dynamic> data) {
    final academic = AcademicCatalog.fromJson(data);
    final teachers = enrollmentList(data['teachers'])
        .map((v) => SchoolTeacher.fromJson(enrollmentMap(v)))
        .toList();
    final subjects = enrollmentList(data['subjects'])
        .map((v) => CurriculumSubject.fromJson(enrollmentMap(v)))
        .toList();
    final assignments = enrollmentList(data['assignments'])
        .map((v) => TeacherAssignment.fromJson(enrollmentMap(v)))
        .toList();
    final teacherIds = teachers.map((v) => v.id).toSet();
    final subjectIds = subjects.map((v) => v.id).toSet();
    final sectionIds = academic.sections.map((v) => v.id).toSet();
    if (teacherIds.length != teachers.length ||
        subjectIds.length != subjects.length ||
        assignments.map((v) => v.id).toSet().length != assignments.length ||
        assignments.map((v) => v.identity).toSet().length !=
            assignments.length ||
        teachers.any((v) => v.schoolId != academic.school.id) ||
        subjects.any((v) => v.schoolId != academic.school.id) ||
        assignments.any(
          (v) =>
              v.schoolId != academic.school.id ||
              !teacherIds.contains(v.teacherId) ||
              !subjectIds.contains(v.subjectId) ||
              !sectionIds.contains(v.sectionId),
        )) {
      throw const FormatException('Teacher assignment scope mismatch');
    }
    return TeacherAssignmentsCatalog._(
      academic,
      teachers,
      subjects,
      assignments,
    );
  }
  bool canCreate(TeacherAssignmentDraft draft) =>
      draft.valid &&
      teachers.any((v) => v.id == draft.teacherId && v.active) &&
      subjects.any((v) => v.id == draft.subjectId && v.active) &&
      academic.sections.any((v) => v.id == draft.sectionId) &&
      !assignments.any((v) => v.identity == draft.identity);
  String sectionLabel(int id) {
    final section = academic.sections.firstWhere((v) => v.id == id);
    final year = academic.years.firstWhere((v) => v.id == section.yearId);
    final grade = academic.grades.firstWhere((v) => v.id == section.gradeId);
    return '${year.name} — ${grade.name} — ${section.name}';
  }
}
