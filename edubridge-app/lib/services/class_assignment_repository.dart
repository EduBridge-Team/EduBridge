import 'dart:convert';
import '../model/enrollment/enrollment_models.dart';
import '../model/class_lessons/class_lesson_catalog.dart';
import '../model/class_lessons/class_lesson_assignment.dart';
import 'enrollment/enrollment_api_client.dart';

abstract interface class ClassAssignmentGateway {
  Future<ClassAssignmentOptions> load();
  Future<int> assign(ClassAssignmentOptions expected, ClassAssignmentDraft draft, String key);
}

/// Proposed capability-gated contract. No existing lesson creation route is changed.
class ClassAssignmentRepository implements ClassAssignmentGateway {
  ClassAssignmentRepository({required this.section, EnrollmentApiClient? client}) : _client = client ?? EnrollmentApiClient();
  final ClassLessonSection section;
  final EnrollmentApiClient _client;
  String get _root => '/sections/${section.id}/lesson-assignments';
  @override
  Future<ClassAssignmentOptions> load() async {
    final data = await _client.get('$_root/options');
    try { return ClassAssignmentOptions.fromJson(data, section); }
    on FormatException { throw const EnrollmentApiException(EnrollmentFailure.invalidResponse); }
  }
  @override
  Future<int> assign(ClassAssignmentOptions expected, ClassAssignmentDraft draft, String key) async {
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(key) || !draft.fits(expected)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await load();
    if (current.fingerprint != expected.fingerprint) throw const EnrollmentApiException(EnrollmentFailure.conflict);
    late final Map<String, dynamic> receipt;
    try {
      receipt = await _client.post(_root, {
        'school_id': section.schoolId, 'academic_year_id': section.yearId,
        'expected_revision': expected.revision, 'request_key': key,
        'lesson_id': draft.lessonId, 'students': draft.payloadStudents,
      });
    } on EnrollmentApiException catch (error) {
      if ([EnrollmentFailure.conflict, EnrollmentFailure.validation, EnrollmentFailure.forbidden,
        EnrollmentFailure.session, EnrollmentFailure.unavailable, EnrollmentFailure.rateLimited].contains(error.failure)) rethrow;
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    } on Object { throw const EnrollmentApiException(EnrollmentFailure.uncertain); }
    // A failure after POST may follow a committed assignment, including 403/404.
    try {
      final id = _verify(receipt, draft, key);
      if (_verify(await _client.get('$_root/$id'), draft, key) != id) {
        throw const FormatException('Unconfirmed assignment');
      }
      return id;
    } on Object { throw const EnrollmentApiException(EnrollmentFailure.uncertain); }
  }
  int _verify(Map<String, dynamic> data, ClassAssignmentDraft draft, String key) {
    if (data['contract_version'] != 1 || data['section_id'] != section.id ||
        data['school_id'] != section.schoolId || data['academic_year_id'] != section.yearId ||
        data['lesson_id'] != draft.lessonId || data['request_key'] != key || data['status'] != 'assigned') {
      throw const FormatException('Mismatched assignment receipt');
    }
    final students = <Map<String, dynamic>>[];
    for (final item in enrollmentList(data['students'])) {
      final student = enrollmentMap(item);
      final goal = student['iep_goal'] == null ? null : enrollmentMap(student['iep_goal']);
      if (student['adaptation'] is! String) throw const FormatException('Missing adaptation');
      students.add({'child_id': enrollmentId(student['child_id']),
        'iep_goal': goal == null ? null : {'plan_id': enrollmentId(goal['plan_id']),
          'version_id': enrollmentId(goal['version_id']), 'goal_id': enrollmentId(goal['goal_id'])},
        'adaptation': student['adaptation']});
    }
    students.sort((a, b) => (a['child_id'] as int).compareTo(b['child_id'] as int));
    if (jsonEncode(students) != jsonEncode(draft.payloadStudents)) throw const FormatException('Mismatched student assignment');
    return enrollmentId(data['assignment_id']);
  }
}
