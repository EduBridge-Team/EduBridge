import '../model/institutions/institution_attendance_report.dart';
import '../model/institutions/institution_timetable.dart';
import '../model/schools/academic_catalog.dart';
import 'enrollment/enrollment_api_client.dart';
import 'institution_academic_repository.dart';

abstract interface class InstitutionAttendanceReportGateway {
  Future<InstitutionAttendanceReport> loadReport({DateTime? from, DateTime? to, int? sectionId});
}
class InstitutionAttendanceReportRepository implements InstitutionAttendanceReportGateway {
  InstitutionAttendanceReportRepository({required this.organizationSlug, required this.organizationId,
    required this.schoolId, EnrollmentApiClient? client}) : _client = client ?? EnrollmentApiClient();
  final String organizationSlug;
  final int organizationId, schoolId;
  final EnrollmentApiClient _client;
  @override
  Future<InstitutionAttendanceReport> loadReport({DateTime? from, DateTime? to, int? sectionId}) async {
    from = from == null ? null : timetableDate(from); to = to == null ? null : timetableDate(to);
    if ((from != null && to != null && to.isBefore(from)) || (sectionId != null && sectionId <= 0)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final academic = await InstitutionAcademicRepository(organizationSlug: organizationSlug, schoolId: schoolId, client: _client).load();
    if (academic.organizationId != organizationId) throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    if (sectionId != null && !academic.sections.any((s) => s.id == sectionId)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final query = <String, String>{if (from != null) 'from': academicDateText(from),
      if (to != null) 'to': academicDateText(to), if (sectionId != null) 'section_id': '$sectionId'};
    final path = '/institutions/${Uri.encodeComponent(organizationSlug)}/schools/$schoolId/attendance/report';
    final data = await _client.get(query.isEmpty ? path : '$path?${Uri(queryParameters: query).query}');
    try {
      return InstitutionAttendanceReport.fromJson(academic, data, from: from, to: to, sectionId: sectionId);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
