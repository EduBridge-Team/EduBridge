import '../enrollment/enrollment_models.dart';

class ClassLessonStudent {
  ClassLessonStudent._(this.childId, this.name, this.state, this.score, this.maximum,
    this.goalTitle, this.goalId, this.planId, this.versionId, this.adaptation);
  final int childId;
  final String name;
  final String? state, goalTitle, adaptation;
  final int? goalId, planId, versionId;
  final num? score, maximum;
  factory ClassLessonStudent.fromJson(Map<String, dynamic> data) {
    final child = enrollmentId(data['child_id']);
    final state = data['state'];
    if (state != null && !['not_started', 'in_progress', 'completed'].contains(state)) {
      throw const FormatException('Unknown lesson result state');
    }
    final score = data['score'], max = data['maximum'];
    if ((score == null) != (max == null) ||
        (score != null && (score is! num || max is! num || !score.isFinite || !max.isFinite ||
          score < 0 || max <= 0 || score > max))) throw const FormatException('Invalid result');
    if (data['adaptation_summary'] != null && data['adaptation_summary'] is! String) {
      throw const FormatException('Invalid adaptation');
    }
    String? goalTitle;
    int? goalId, planId, versionId;
    if (data['iep_goal'] != null) {
      final goal = enrollmentMap(data['iep_goal']);
      if (enrollmentId(goal['child_id']) != child || goal['version_status'] != 'approved' ||
          goal['is_current_approved'] != true) throw const FormatException('Foreign or unapproved goal');
      goalTitle = enrollmentText(goal['title']); goalId = enrollmentId(goal['goal_id']);
      planId = enrollmentId(goal['plan_id']); versionId = enrollmentId(goal['version_id']);
    }
    return ClassLessonStudent._(child, enrollmentText(data['child_name']), state as String?,
      score as num?, max as num?, goalTitle, goalId, planId, versionId, data['adaptation_summary'] as String?);
  }
}
class ClassLesson {
  ClassLesson._(this.id, this.title, List<ClassLessonStudent> students) : students = List.unmodifiable(students);
  final int id;
  final String title;
  final List<ClassLessonStudent> students;
  factory ClassLesson.fromJson(Map<String, dynamic> data) {
    final students = enrollmentList(data['students']).map((s) => ClassLessonStudent.fromJson(enrollmentMap(s))).toList();
    if (students.map((s) => s.childId).toSet().length != students.length) {
      throw const FormatException('Duplicate student result');
    }
    return ClassLesson._(enrollmentId(data['lesson_id']), enrollmentText(data['title']), students);
  }
}
class ClassLessonSection {
  ClassLessonSection._(this.id, this.schoolId, this.yearId, this.name, this.schoolName, this.yearName,
    List<ClassLesson> lessons) : lessons = List.unmodifiable(lessons);
  final int id, schoolId, yearId;
  final String name, schoolName, yearName;
  final List<ClassLesson> lessons;
  factory ClassLessonSection.fromJson(Map<String, dynamic> data) {
    final lessons = enrollmentList(data['lessons']).map((l) => ClassLesson.fromJson(enrollmentMap(l))).toList();
    if (lessons.map((l) => l.id).toSet().length != lessons.length) throw const FormatException('Duplicate lesson');
    return ClassLessonSection._(enrollmentId(data['section_id']), enrollmentId(data['school_id']),
      enrollmentId(data['academic_year_id']), enrollmentText(data['section_name']),
      enrollmentText(data['school_name']), enrollmentText(data['academic_year_name']), lessons);
  }
}
class ClassLessonCatalog {
  ClassLessonCatalog._(List<ClassLessonSection> sections) : sections = List.unmodifiable(sections);
  final List<ClassLessonSection> sections;
  factory ClassLessonCatalog.fromJson(Map<String, dynamic> data) {
    if (data['contract_version'] != 1) throw const FormatException('Unsupported class lesson contract');
    final sections = enrollmentList(data['sections']).map((s) => ClassLessonSection.fromJson(enrollmentMap(s))).toList();
    if (sections.map((s) => s.id).toSet().length != sections.length) throw const FormatException('Duplicate section');
    return ClassLessonCatalog._(sections);
  }
}
