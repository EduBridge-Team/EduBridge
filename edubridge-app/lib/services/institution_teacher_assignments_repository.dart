import '../model/institutions/institution_teacher_assignments.dart';
import '../model/schools/teacher_assignment.dart';
import 'enrollment/enrollment_api_client.dart';
import 'institution_academic_repository.dart';

abstract interface class InstitutionTeacherAssignmentsGateway {
  Future<InstitutionTeacherAssignments> load();
  Future<void> create(TeacherAssignmentDraft draft);
}

abstract interface class InstitutionTeacherAssignmentRemover implements InstitutionTeacherAssignmentsGateway {
  Future<void> remove(InstitutionTeacherAssignments expected, InstitutionTeacherAssignment assignment);
}

class InstitutionTeacherAssignmentsRepository
    implements InstitutionTeacherAssignmentRemover {
  InstitutionTeacherAssignmentsRepository({
    required this.organizationSlug,
    required this.organizationId,
    required this.schoolId,
    EnrollmentApiClient? client,
  }) : _client = client ?? EnrollmentApiClient();
  final String organizationSlug;
  final int organizationId, schoolId;
  final EnrollmentApiClient _client;
  String get _base =>
      '/institutions/${Uri.encodeComponent(organizationSlug)}/schools/$schoolId';

  @override
  Future<InstitutionTeacherAssignments> load() async {
    final academic = await InstitutionAcademicRepository(
      organizationSlug: organizationSlug, schoolId: schoolId, client: _client,
    ).load();
    if (academic.organizationId != organizationId) {
      throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    }
    final data = await _client.get('$_base/participants');
    try {
      return InstitutionTeacherAssignments.fromJson(academic, data);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  @override
  Future<void> remove(InstitutionTeacherAssignments expected, InstitutionTeacherAssignment assignment) async {
    if (expected.academic.organizationSlug != organizationSlug || expected.academic.organizationId != organizationId ||
        expected.academic.school.id != schoolId || !expected.assignments.any((a) =>
          a.id == assignment.id && a.draft.identity == assignment.draft.identity)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await load();
    final matches = current.assignments.where((a) => a.id == assignment.id);
    if (matches.length != 1 || matches.single.draft.identity != assignment.draft.identity) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    final receipt = await _client.delete('$_base/academic/teacher-assignments/${assignment.id}');
    if (receipt['removed'] != true) throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    late final InstitutionTeacherAssignments after;
    try {
      after = await load();
    } on EnrollmentApiException catch (e) {
      if (e.failure == EnrollmentFailure.session || e.failure == EnrollmentFailure.forbidden ||
          e.failure == EnrollmentFailure.invalidResponse || e.failure == EnrollmentFailure.unavailable) rethrow;
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    }
    if (after.assignments.any((a) => a.id == assignment.id || a.draft.identity == assignment.draft.identity)) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  @override
  Future<void> create(TeacherAssignmentDraft draft) async {
    if (!draft.valid) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final before = await load();
    if (!before.canCreate(draft)) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    final receipt = await _client.post(
      '$_base/academic/teacher-assignments', draft.toJson(),
    );
    if (receipt['assigned'] != true) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    // The existing POST returns no record. Confirm through a scoped read;
    // never invent an assignment id or a version to reuse school-portal models.
    final after = await load();
    final matches = after.assignments.where((v) => v.draft.identity == draft.identity);
    if (matches.length != 1 ||
        before.assignments.any((v) => v.id == matches.single.id)) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
