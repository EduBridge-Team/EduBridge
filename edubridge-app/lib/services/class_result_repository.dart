import 'dart:convert';
import '../model/enrollment/enrollment_models.dart';
import '../model/class_lessons/class_lesson_result.dart';
import 'enrollment/enrollment_api_client.dart';

abstract interface class ClassResultGateway {
  Future<ClassResultOptions> load();
  Future<int> record(ClassResultOptions expected, ClassResultDraft draft, String key);
}

/// Proposed atomic student-result/optional goal-evidence contract, separate from game scores.
class ClassResultRepository implements ClassResultGateway {
  ClassResultRepository({required this.source, EnrollmentApiClient? client}) : _client = client ?? EnrollmentApiClient();
  final ClassResultSource source;
  final EnrollmentApiClient _client;
  String get _root => '/sections/${source.section.id}/lesson-assignments/${source.lesson.assignmentId}/students/${source.student.childId}';
  @override
  Future<ClassResultOptions> load() async {
    if (!source.valid) throw const EnrollmentApiException(EnrollmentFailure.unavailable);
    final data = await _client.get('$_root/result-options');
    try { return ClassResultOptions.fromJson(data, source); }
    on FormatException { throw const EnrollmentApiException(EnrollmentFailure.invalidResponse); }
  }
  @override
  Future<int> record(ClassResultOptions expected, ClassResultDraft draft, String key) async {
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(key) || !draft.fits(expected)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    if ((await load()).fingerprint != expected.fingerprint) throw const EnrollmentApiException(EnrollmentFailure.conflict);
    late final Map<String, dynamic> receipt;
    try {
      receipt = await _client.post('$_root/results', {...source.identity, 'iep_goal': source.goal,
        'expected_revision': expected.revision, 'request_key': key, ...draft.payload(expected)});
    } on EnrollmentApiException catch (error) {
      if ([EnrollmentFailure.conflict, EnrollmentFailure.validation, EnrollmentFailure.forbidden,
        EnrollmentFailure.session, EnrollmentFailure.unavailable, EnrollmentFailure.rateLimited].contains(error.failure)) rethrow;
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    } on Object { throw const EnrollmentApiException(EnrollmentFailure.uncertain); }
    // Any failure after a successful POST may follow a committed result/evidence.
    try {
      final id = _verify(receipt, expected, draft, key);
      final read = await _client.get('$_root/results/$id');
      if (_verify(read, expected, draft, key) != id || read['goal_evidence_id'] != receipt['goal_evidence_id']) {
        throw const FormatException('Unconfirmed result');
      }
      return id;
    } on Object { throw const EnrollmentApiException(EnrollmentFailure.uncertain); }
  }
  int _verify(Map<String, dynamic> data, ClassResultOptions options, ClassResultDraft draft, String key) {
    if (data['contract_version'] != 1 || !source.matches(data) || data['request_key'] != key ||
        data['status'] != 'recorded') throw const FormatException('Invalid result receipt');
    final rawGoal = data['iep_goal'] == null ? null : enrollmentMap(data['iep_goal']);
    final goal = rawGoal == null ? null : {'plan_id': enrollmentId(rawGoal['plan_id']),
      'version_id': enrollmentId(rawGoal['version_id']), 'goal_id': enrollmentId(rawGoal['goal_id'])};
    final rawMeasurement = data['goal_measurement'] == null ? null : enrollmentMap(data['goal_measurement']);
    final measurement = rawMeasurement == null ? null : {'value': rawMeasurement['value'], 'unit': rawMeasurement['unit']};
    if (jsonEncode(goal) != jsonEncode(source.goal) || data['state'] != draft.state ||
        data['observed_on'] != lessonResultDay(draft.observedOn) || data['observation'] != draft.observation.trim() ||
        data['score'] != draft.score || data['maximum'] != draft.maximum ||
        (draft.goalValue == null ? measurement != null : measurement == null ||
          measurement['value'] != draft.goalValue || measurement['unit'] != options.goalUnit)) {
      throw const FormatException('Mismatched recorded result');
    }
    if (source.goal == null) {
      if (data['goal_evidence_id'] != null) throw const FormatException('Unexpected goal evidence');
    } else { enrollmentId(data['goal_evidence_id']); }
    return enrollmentId(data['result_id']);
  }
}
