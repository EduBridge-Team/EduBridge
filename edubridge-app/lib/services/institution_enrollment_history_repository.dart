import '../model/institutions/institution_enrollment_history.dart';
import 'enrollment/enrollment_api_client.dart';
import 'institution_academic_repository.dart';

abstract interface class InstitutionEnrollmentHistoryGateway {
  Future<InstitutionEnrollmentHistory> load();
}

abstract interface class InstitutionEnrollmentTransferGateway implements InstitutionEnrollmentHistoryGateway {
  Future<void> transfer(int enrollmentId, int sectionId);
}

class InstitutionEnrollmentHistoryRepository implements InstitutionEnrollmentTransferGateway {
  InstitutionEnrollmentHistoryRepository({
    required this.organizationSlug, required this.organizationId,
    required this.schoolId, EnrollmentApiClient? client,
  }) : _client = client ?? EnrollmentApiClient();
  final String organizationSlug;
  final int organizationId, schoolId;
  final EnrollmentApiClient _client;
  @override
  Future<void> transfer(int enrollmentId, int sectionId) async {
    final before = await load();
    if (!before.transferTargets(enrollmentId).any((s) => s.id == sectionId)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final source = before.records.singleWhere((r) => r.id == enrollmentId);
    final response = await _client.post(
      '/institutions/${Uri.encodeComponent(organizationSlug)}/schools/$schoolId/academic/student-enrollments/$enrollmentId/transfer',
      {'section_id': sectionId},
    );
    if (response['transferred'] != true) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    final after = await load();
    final old = after.records.where((r) => r.id == enrollmentId);
    final target = after.records.where((r) => r.childId == source.childId && r.sectionId == sectionId && r.status == InstitutionEnrollmentStatus.active);
    if (old.length != 1 || old.single.childId != source.childId ||
        old.single.sectionId != source.sectionId ||
        old.single.status != InstitutionEnrollmentStatus.transferred ||
        old.single.end == null || target.length != 1 || target.single.id == enrollmentId) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  @override
  Future<InstitutionEnrollmentHistory> load() async {
    final academic = await InstitutionAcademicRepository(
      organizationSlug: organizationSlug, schoolId: schoolId, client: _client,
    ).load();
    if (academic.organizationId != organizationId) {
      throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    }
    final data = await _client.get(
      '/institutions/${Uri.encodeComponent(organizationSlug)}/schools/$schoolId/academic/student-enrollments',
    );
    try {
      return InstitutionEnrollmentHistory.fromJson(academic, data);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
