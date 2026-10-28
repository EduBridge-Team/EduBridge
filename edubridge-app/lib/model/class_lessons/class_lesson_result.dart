import 'dart:convert';
import '../enrollment/enrollment_models.dart';
import 'class_lesson_catalog.dart';

String lessonResultDay(DateTime day) => '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
DateTime _day(dynamic value) {
  if (value is! String) throw const FormatException('Missing day');
  final date = DateTime.tryParse(value);
  if (date == null || lessonResultDay(date) != value) throw const FormatException('Invalid day');
  return date;
}

class ClassResultSource {
  const ClassResultSource({required this.section, required this.lesson, required this.student});
  final ClassLessonSection section;
  final ClassLesson lesson;
  final ClassLessonStudent student;
  Map<String, dynamic> get identity => {'section_id': section.id, 'school_id': section.schoolId,
    'academic_year_id': section.yearId, 'assignment_id': lesson.assignmentId,
    'lesson_id': lesson.id, 'child_id': student.childId};
  Map<String, dynamic>? get goal => student.goalId == null ? null : {
    'plan_id': student.planId, 'version_id': student.versionId, 'goal_id': student.goalId};
  bool get valid => lesson.assignmentId != null && section.lessons.contains(lesson) && lesson.students.contains(student);
  bool matches(Map<String, dynamic> data) => valid &&
    identity.entries.every((e) => data[e.key] == e.value);
}

class ClassResultOptions {
  ClassResultOptions._(this.revision, this.canRecord, List<String> states, this.earliest, this.latest, this.goalUnit)
    : states = List.unmodifiable(states);
  final String revision;
  final bool canRecord;
  final List<String> states;
  final DateTime earliest, latest;
  final String? goalUnit;
  factory ClassResultOptions.fromJson(Map<String, dynamic> data, ClassResultSource source) {
    if (data['contract_version'] != 1 || !source.matches(data) || data['can_record'] is! bool) {
      throw const FormatException('Invalid result options scope');
    }
    final states = enrollmentList(data['allowed_states']).map(enrollmentText).toList();
    if (states.toSet().length != states.length || states.any((s) => !['in_progress', 'completed'].contains(s))) {
      throw const FormatException('Invalid result states');
    }
    // Validate current approved child ownership before comparing the assignment link.
    final returned = ClassLessonStudent.fromJson({'child_id': source.student.childId,
      'child_name': source.student.name, 'iep_goal': data['iep_goal']});
    final goal = returned.goalId == null ? null : {'plan_id': returned.planId,
      'version_id': returned.versionId, 'goal_id': returned.goalId};
    if (jsonEncode(goal) != jsonEncode(source.goal)) throw const FormatException('Changed assignment goal');
    final unit = data['goal_unit'] == null ? null : enrollmentText(data['goal_unit']);
    if (goal == null && unit != null) throw const FormatException('Measurement without a goal');
    final earliest = _day(data['earliest_on']), latest = _day(data['latest_on']);
    if (latest.isBefore(earliest)) throw const FormatException('Invalid observation window');
    return ClassResultOptions._(enrollmentText(data['revision']), data['can_record'] as bool, states, earliest, latest, unit);
  }
  String get fingerprint => jsonEncode([revision, canRecord, states, lessonResultDay(earliest), lessonResultDay(latest), goalUnit]);
}

class ClassResultDraft {
  const ClassResultDraft({required this.state, required this.observedOn, required this.observation,
    this.score, this.maximum, this.goalValue});
  final String state, observation;
  final DateTime observedOn;
  final num? score, maximum, goalValue;
  bool fits(ClassResultOptions options) => options.canRecord && options.states.contains(state) &&
    !observedOn.isBefore(options.earliest) && !observedOn.isAfter(options.latest) &&
    observation.trim().isNotEmpty && observation.trim().length <= 2000 &&
    ((score == null && maximum == null) || (score != null && maximum != null &&
      score!.isFinite && maximum!.isFinite && maximum! > 0 && score! >= 0 && score! <= maximum!)) &&
    (goalValue == null || (options.goalUnit != null && goalValue!.isFinite && goalValue! >= 0));
  Map<String, dynamic> payload(ClassResultOptions options) => {'state': state,
    'observed_on': lessonResultDay(observedOn), 'observation': observation.trim(),
    'score': score, 'maximum': maximum, 'goal_measurement': goalValue == null ? null : {'value': goalValue, 'unit': options.goalUnit}};
}
