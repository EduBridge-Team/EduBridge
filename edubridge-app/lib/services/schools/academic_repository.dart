import '../../model/enrollment/enrollment_models.dart';
import '../../model/schools/academic_catalog.dart';
import '../enrollment/enrollment_api_client.dart';

abstract interface class AcademicGateway {
  Future<AcademicCatalog> load();
  Future<void> create(int schoolId, AcademicDraft draft);
}

class AcademicRepository implements AcademicGateway {
  AcademicRepository({EnrollmentApiClient? client})
      : _client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient _client;

  @override
  Future<AcademicCatalog> load() async {
    final context = await _client.get('/school/context');
    final data = await _client.get('/school/academic');
    try {
      final identity = SchoolPortalIdentity.fromJson(enrollmentMap(context['school']));
      final catalog = AcademicCatalog.fromJson(data);
      if (catalog.school.id != identity.school.id ||
          catalog.school.name != identity.school.name) {
        throw const FormatException('Foreign school');
      }
      return catalog;
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  @override
  Future<void> create(int schoolId, AcademicDraft draft) async {
    if (schoolId <= 0 || !draft.valid) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final route = switch (draft.kind) {
      AcademicKind.year => 'years',
      AcademicKind.grade => 'grades',
      AcademicKind.section => 'sections',
    };
    // Expected school asserts the page context; it never grants authorization.
    final data = await _client.post('/school/academic/$route',
        {...draft.toJson(), 'expected_school_id': schoolId});
    try {
      if (enrollmentId(data['school_id']) != schoolId) {
        throw const FormatException('Foreign school receipt');
      }
      final item = enrollmentMap(data['item']);
      final bool matches;
      switch (draft.kind) {
        case AcademicKind.year:
          final year = AcademicYear.fromJson(item);
          matches = year.schoolId == schoolId && year.name == draft.name.trim() &&
              academicDateText(year.start) == academicDateText(draft.start!) &&
              academicDateText(year.end) == academicDateText(draft.end!) &&
              year.current == draft.current;
          break;
        case AcademicKind.grade:
          final grade = AcademicGrade.fromJson(item);
          matches = grade.schoolId == schoolId && grade.name == draft.name.trim();
          break;
        case AcademicKind.section:
          final section = AcademicSection.fromJson(item);
          matches = section.schoolId == schoolId && section.name == draft.name.trim() &&
              section.yearId == draft.yearId && section.gradeId == draft.gradeId &&
              section.capacity == draft.capacity;
          break;
      }
      if (!matches) throw const FormatException('Saved fields mismatch');
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
