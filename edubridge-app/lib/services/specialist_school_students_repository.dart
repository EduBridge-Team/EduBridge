import 'dart:math';
import '../model/enrollment/enrollment_models.dart';
import '../model/schools/specialist_school_students.dart';
import 'enrollment/enrollment_api_client.dart';

abstract interface class SpecialistSchoolStudentsGateway {
  Future<SpecialistSchoolDirectory> schools();
  Future<SpecialistSchoolRoster> students(int specialistId, SpecialistSchool school);
  Future<void> follow(SpecialistSchoolRoster expected, SpecialistSchoolStudent student);
}
class SpecialistSchoolStudentsRepository implements SpecialistSchoolStudentsGateway {
  SpecialistSchoolStudentsRepository({EnrollmentApiClient? client})
      : _client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient _client;
  T _parse<T>(T Function() parse) {
    try { return parse(); } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
  Future<int> _identity() async {
    final data = await _client.get('/me');
    return _parse(() {
      final user = enrollmentMap(data['user']);
      if (user['role'] != 'specialist') throw const EnrollmentApiException(EnrollmentFailure.forbidden);
      return enrollmentId(user['id']);
    });
  }
  Future<void> _checkIdentity(int expected) async {
    if (await _identity() != expected) throw const EnrollmentApiException(EnrollmentFailure.session);
  }
  String _base(SpecialistSchool school) => '/specialists/me/schools/${school.id}';
  @override
  Future<SpecialistSchoolDirectory> schools() async {
    final id = await _identity();
    final data = await _client.get('/specialists/me/schools');
    await _checkIdentity(id);
    return _parse(() => SpecialistSchoolDirectory.fromJson(id, data));
  }
  @override
  Future<SpecialistSchoolRoster> students(int specialistId, SpecialistSchool school) async {
    await _checkIdentity(specialistId);
    final data = await _client.get('${_base(school)}/students');
    await _checkIdentity(specialistId);
    return _parse(() => SpecialistSchoolRoster.fromJson(specialistId, school, data));
  }
  String _key() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
  @override
  Future<void> follow(SpecialistSchoolRoster expected, SpecialistSchoolStudent student) async {
    if (!student.canFollow || student.following || !expected.students.any((s) =>
        s.sameEnrollment(student) && s.canFollow && !s.following)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await students(expected.specialistId, expected.school);
    if (current.revision != expected.revision || !current.students.any((s) =>
        s.sameEnrollment(student) && s.canFollow && !s.following)) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    final receipt = await _client.post('${_base(expected.school)}/students/${student.id}/follow-ups', {
      'expected_revision': expected.revision, 'expected_assignment_id': expected.school.assignmentId,
      'expected_enrollment_id': student.enrollmentId, 'idempotency_key': _key(),
    });
    final followupId = _parse(() {
      if (enrollmentId(receipt['specialist_id']) != expected.specialistId ||
          enrollmentId(receipt['school_id']) != expected.school.id ||
          enrollmentId(receipt['organization_id']) != expected.school.organizationId ||
          enrollmentId(receipt['assignment_id']) != expected.school.assignmentId ||
          enrollmentId(receipt['child_id']) != student.id ||
          enrollmentId(receipt['enrollment_id']) != student.enrollmentId) {
        throw const FormatException('Foreign follow-up receipt');
      }
      return enrollmentId(receipt['followup_id']);
    });
    late final SpecialistSchoolRoster after;
    try { after = await students(expected.specialistId, expected.school); }
    on EnrollmentApiException catch (e) {
      if (const {EnrollmentFailure.session, EnrollmentFailure.forbidden,
          EnrollmentFailure.invalidResponse, EnrollmentFailure.unavailable}.contains(e.failure)) rethrow;
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    }
    if (!after.students.any((s) => s.sameEnrollment(student) && s.following && s.followupId == followupId)) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}

