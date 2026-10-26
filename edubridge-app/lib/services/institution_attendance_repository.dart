import '../model/institutions/institution_attendance.dart';
import '../model/schools/academic_catalog.dart';
import 'enrollment/enrollment_api_client.dart';
import 'institution_academic_repository.dart';

abstract interface class InstitutionAttendanceGateway {
  Future<InstitutionAttendanceView> load({DateTime? date, int? sessionId});
}

class InstitutionAttendanceRepository implements InstitutionAttendanceGateway {
  InstitutionAttendanceRepository({required this.organizationSlug, required this.organizationId,
    required this.schoolId, EnrollmentApiClient? client}) : _client = client ?? EnrollmentApiClient();
  final String organizationSlug;
  final int organizationId, schoolId;
  final EnrollmentApiClient _client;
  @override
  Future<InstitutionAttendanceView> load({DateTime? date, int? sessionId}) async {
    if (sessionId != null && sessionId < 1) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final academic = await InstitutionAcademicRepository(organizationSlug: organizationSlug,
      schoolId: schoolId, client: _client).load();
    if (academic.organizationId != organizationId) {
      throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    }
    final root = '/institutions/${Uri.encodeComponent(organizationSlug)}/schools/$schoolId/attendance';
    final data = await _client.get(date == null ? root : '$root?date=${academicDateText(date)}');
    try {
      final catalog = InstitutionAttendanceView.fromJson(academic, data, date: date);
      if (sessionId == null) return catalog;
      if (!catalog.sessions.any((s) => s.id == sessionId)) {
        throw const EnrollmentApiException(EnrollmentFailure.unavailable);
      }
      final detail = await _client.get('$root/$sessionId');
      return catalog.withDetail(sessionId, detail);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
