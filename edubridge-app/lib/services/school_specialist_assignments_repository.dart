import 'dart:math';
import '../model/institutions/school_specialist_assignments.dart';
import '../model/enrollment/enrollment_models.dart';
import 'enrollment/enrollment_api_client.dart';

abstract interface class SchoolSpecialistAssignmentsGateway {
  Future<SchoolSpecialistAssignments> load();
  Future<void> assign(SchoolSpecialistAssignments expected, int specialistId);
  Future<void> end(SchoolSpecialistAssignments expected, SchoolSpecialistAssignment assignment);
}

/// Proposed institution contract; never uses child care-team endpoints.
class SchoolSpecialistAssignmentsRepository implements SchoolSpecialistAssignmentsGateway {
  SchoolSpecialistAssignmentsRepository({required this.organizationSlug,
    required this.organizationId, required this.schoolId, EnrollmentApiClient? client})
      : _client = client ?? EnrollmentApiClient();
  final String organizationSlug;
  final int organizationId, schoolId;
  final EnrollmentApiClient _client;
  String get _base => '/institutions/${Uri.encodeComponent(organizationSlug)}/schools/$schoolId/specialist-assignments';
  T _parse<T>(T Function() read) {
    try { return read(); } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
  @override
  Future<SchoolSpecialistAssignments> load() async {
    if (organizationId < 1 || schoolId < 1 ||
        !RegExp(r'^[a-z0-9][a-z0-9-]{1,79}$').hasMatch(organizationSlug)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final data = await _client.get(_base);
    return _parse(() => SchoolSpecialistAssignments.fromJson(organizationId, schoolId, data));
  }
  Future<SchoolSpecialistAssignments> _preflight(SchoolSpecialistAssignments expected) async {
    if (expected.organizationId != organizationId || expected.schoolId != schoolId) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await load();
    if (current.revision != expected.revision || current.effectiveOn != expected.effectiveOn) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    return current;
  }
  Future<SchoolSpecialistAssignments> _after() async {
    try { return await load(); } on EnrollmentApiException catch (e) {
      if (const {EnrollmentFailure.session, EnrollmentFailure.forbidden,
          EnrollmentFailure.invalidResponse, EnrollmentFailure.unavailable}.contains(e.failure)) rethrow;
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    }
  }
  String _key() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
  String _date(DateTime value) => value.toIso8601String().substring(0, 10);
  @override
  Future<void> assign(SchoolSpecialistAssignments expected, int specialistId) async {
    if (!expected.canAdd(specialistId)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await _preflight(expected);
    if (!current.canAdd(specialistId)) throw const EnrollmentApiException(EnrollmentFailure.conflict);
    final receipt = await _client.post(_base, {
      'specialist_id': specialistId, 'expected_revision': expected.revision,
      'effective_on': _date(expected.effectiveOn), 'idempotency_key': _key(),
    });
    final assignment = _receipt(receipt);
    if (!assignment.active || assignment.specialistId != specialistId ||
        assignment.startsOn != expected.effectiveOn ||
        expected.assignments.any((a) => a.id == assignment.id)) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    final after = await _after();
    if (!after.assignments.any((a) => a.id == assignment.id && a.specialistId == specialistId &&
        a.startsOn == assignment.startsOn && a.active)) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
  SchoolSpecialistAssignment _receipt(Map<String, dynamic> data) => _parse(() {
    if (enrollmentId(data['organization_id']) != organizationId ||
        enrollmentId(data['school_id']) != schoolId) throw const FormatException('Foreign receipt');
    return SchoolSpecialistAssignment.fromJson(enrollmentMap(data['assignment']));
  });
  @override
  Future<void> end(SchoolSpecialistAssignments expected, SchoolSpecialistAssignment assignment) async {
    if (!assignment.active || !assignment.canEnd ||
        !expected.assignments.any((a) => a.id == assignment.id && a.specialistId == assignment.specialistId &&
            a.startsOn == assignment.startsOn && a.active && a.canEnd)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await _preflight(expected);
    if (!current.assignments.any((a) => a.id == assignment.id && a.specialistId == assignment.specialistId &&
        a.startsOn == assignment.startsOn && a.active && a.canEnd)) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    final receipt = await _client.post('$_base/${assignment.id}/end', {
      'expected_revision': expected.revision, 'expected_specialist_id': assignment.specialistId,
      'effective_on': _date(expected.effectiveOn), 'idempotency_key': _key(),
    }, success: 200);
    final ended = _receipt(receipt);
    if (ended.id != assignment.id || ended.specialistId != assignment.specialistId ||
        ended.startsOn != assignment.startsOn || ended.endedOn != expected.effectiveOn || ended.active) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    final after = await _after();
    if (!after.assignments.any((a) => a.id == ended.id && a.specialistId == ended.specialistId &&
        a.startsOn == ended.startsOn && a.endedOn == ended.endedOn && !a.active)) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}

