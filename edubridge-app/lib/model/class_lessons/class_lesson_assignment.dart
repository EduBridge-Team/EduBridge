import 'dart:convert';
import 'dart:math';
import '../enrollment/enrollment_models.dart';
import 'class_lesson_catalog.dart';

String newClassAssignmentKey() {
  final random = Random.secure();
  return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

class ClassAssignmentGoal {
  ClassAssignmentGoal._(this.id, this.planId, this.versionId, this.title);
  final int id, planId, versionId;
  final String title;
  factory ClassAssignmentGoal.fromJson(Map<String, dynamic> data, int childId) {
    if (enrollmentId(data['child_id']) != childId || data['version_status'] != 'approved' ||
        data['is_current_approved'] != true) throw const FormatException('Invalid goal scope');
    return ClassAssignmentGoal._(enrollmentId(data['goal_id']), enrollmentId(data['plan_id']),
      enrollmentId(data['version_id']), enrollmentText(data['title']));
  }
  Map<String, dynamic> toJson() => {'plan_id': planId, 'version_id': versionId, 'goal_id': id};
}

class ClassAssignmentStudent {
  ClassAssignmentStudent._(this.id, this.name, List<ClassAssignmentGoal> goals) : goals = List.unmodifiable(goals);
  final int id;
  final String name;
  final List<ClassAssignmentGoal> goals;
  factory ClassAssignmentStudent.fromJson(Map<String, dynamic> data) {
    final id = enrollmentId(data['child_id']);
    final goals = enrollmentList(data['goals']).map((g) => ClassAssignmentGoal.fromJson(enrollmentMap(g), id)).toList();
    if (goals.map((g) => g.id).toSet().length != goals.length ||
        goals.map((g) => (g.planId, g.versionId)).toSet().length > 1) {
      throw const FormatException('Ambiguous current approved goals');
    }
    return ClassAssignmentStudent._(id, enrollmentText(data['child_name']), goals);
  }
}

class ClassAssignmentOptions {
  ClassAssignmentOptions._(this.revision, this.canAssign, Map<int, String> lessons,
    List<ClassAssignmentStudent> students) : lessons = Map.unmodifiable(lessons), students = List.unmodifiable(students);
  final String revision;
  final bool canAssign;
  final Map<int, String> lessons;
  final List<ClassAssignmentStudent> students;
  factory ClassAssignmentOptions.fromJson(Map<String, dynamic> data, ClassLessonSection section) {
    if (data['contract_version'] != 1 || data['complete'] != true || data['section_id'] != section.id ||
        data['school_id'] != section.schoolId || data['academic_year_id'] != section.yearId ||
        data['can_assign'] is! bool) throw const FormatException('Invalid assignment scope');
    final lessons = <int, String>{};
    for (final item in enrollmentList(data['lessons'])) {
      final lesson = enrollmentMap(item), id = enrollmentId(lesson['lesson_id']);
      if (lessons.containsKey(id)) throw const FormatException('Duplicate lesson');
      lessons[id] = enrollmentText(lesson['title']);
    }
    final students = enrollmentList(data['students']).map((s) => ClassAssignmentStudent.fromJson(enrollmentMap(s))).toList();
    if (students.map((s) => s.id).toSet().length != students.length) throw const FormatException('Duplicate student');
    return ClassAssignmentOptions._(enrollmentText(data['revision']), data['can_assign'] as bool, lessons, students);
  }
  // Includes names/content as well as identity: changed options invalidate an open confirmation.
  String get fingerprint => jsonEncode([revision, canAssign, lessons.map((k, v) => MapEntry('$k', v)),
    [for (final s in students) [s.id, s.name, [for (final g in s.goals) [g.toJson(), g.title]]]]]);
}

class ClassAssignmentChoice {
  const ClassAssignmentChoice({required this.childId, this.goal, this.adaptation = ''});
  final int childId;
  final ClassAssignmentGoal? goal;
  final String adaptation;
  Map<String, dynamic> toJson() => {'child_id': childId, 'iep_goal': goal?.toJson(), 'adaptation': adaptation.trim()};
}

class ClassAssignmentDraft {
  ClassAssignmentDraft(this.lessonId, List<ClassAssignmentChoice> students) : students = List.unmodifiable(students);
  final int lessonId;
  final List<ClassAssignmentChoice> students;
  bool fits(ClassAssignmentOptions options) => options.canAssign && options.lessons.containsKey(lessonId) &&
    students.isNotEmpty && students.length == options.students.length &&
    students.map((s) => s.childId).toSet().length == students.length &&
    students.every((s) => s.adaptation.trim().length <= 2000 && options.students.any((current) =>
      current.id == s.childId && (s.goal == null || current.goals.any((g) =>
        jsonEncode(g.toJson()) == jsonEncode(s.goal!.toJson())))));
  List<Map<String, dynamic>> get payloadStudents {
    final ordered = [...students]..sort((a, b) => a.childId.compareTo(b.childId));
    return [for (final s in ordered) s.toJson()];
  }
}
