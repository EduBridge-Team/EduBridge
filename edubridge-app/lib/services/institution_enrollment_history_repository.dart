import '../model/institutions/institution_enrollment_history.dart';
import 'enrollment/enrollment_api_client.dart';
import 'institution_academic_repository.dart';

abstract interface class InstitutionEnrollmentHistoryGateway {
  Future<InstitutionEnrollmentHistory> load();
}

class InstitutionEnrollmentHistoryRepository implements InstitutionEnrollmentHistoryGateway {
  InstitutionEnrollmentHistoryRepository({
    required this.organizationSlug, required this.organizationId,
    required this.schoolId, EnrollmentApiClient? client,
  }) : _client = client ?? EnrollmentApiClient();
  final String organizationSlug;
  final int organizationId, schoolId;
  final EnrollmentApiClient _client;
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
