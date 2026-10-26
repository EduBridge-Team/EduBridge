import '../model/enrollment/enrollment_models.dart';
import '../model/institutions/institution_academic_records.dart';
import 'enrollment/enrollment_api_client.dart';

abstract interface class InstitutionAcademicGateway {
  Future<InstitutionAcademicRecords> load();
}

/// Uses the existing institution API; the caller's slug never grants access.
class InstitutionAcademicRepository implements InstitutionAcademicGateway {
  InstitutionAcademicRepository({
    required this.organizationSlug,
    required this.schoolId,
    EnrollmentApiClient? client,
  }) : _client = client ?? EnrollmentApiClient();
  final String organizationSlug;
  final int schoolId;
  final EnrollmentApiClient _client;
  @override
  Future<InstitutionAcademicRecords> load() async {
    if (schoolId < 1 ||
        !RegExp(r'^[a-z0-9][a-z0-9-]{1,79}$').hasMatch(organizationSlug)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final context = await _client.get('/institutions/my-organization');
    late final int organizationId;
    try {
      final organization = enrollmentMap(context['organization']);
      organizationId = enrollmentId(organization['id']);
      if (organization['slug'] != organizationSlug) {
        throw const FormatException('Institution context changed');
      }
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    final data = await _client.get(
      '/institutions/${Uri.encodeComponent(organizationSlug)}/schools/$schoolId/academic',
    );
    try {
      return InstitutionAcademicRecords.fromJson(
        organizationSlug,
        organizationId,
        schoolId,
        data,
      );
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
