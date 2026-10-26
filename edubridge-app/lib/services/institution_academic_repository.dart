import '../model/enrollment/enrollment_models.dart';
import '../model/institutions/institution_academic_records.dart';
import '../model/schools/academic_catalog.dart';
import 'enrollment/enrollment_api_client.dart';

abstract interface class InstitutionAcademicGateway {
  Future<InstitutionAcademicRecords> load();
}

abstract interface class InstitutionAcademicWriter
    implements InstitutionAcademicGateway {
  Future<void> create(InstitutionAcademicRecords expected, AcademicDraft draft);
}

/// Uses the existing institution API; the caller's slug never grants access.
class InstitutionAcademicRepository implements InstitutionAcademicWriter {
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

  @override
  Future<void> create(
    InstitutionAcademicRecords expected,
    AcademicDraft draft,
  ) async {
    if (!draft.valid ||
        expected.school.id != schoolId ||
        expected.organizationSlug != organizationSlug) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    // Refresh authority and available parents before any mutation. The backend
    // still authorizes the POST and enforces its own tenant and FK constraints.
    final current = await load();
    if (current.organizationId != expected.organizationId) {
      throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    }
    if (draft.kind == AcademicKind.section &&
        (!current.years.any((y) => y.id == draft.yearId) ||
            !current.grades.any((g) => g.id == draft.gradeId))) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    final route = switch (draft.kind) {
      AcademicKind.year => 'years',
      AcademicKind.grade => 'grades',
      AcademicKind.section => 'sections',
    };
    final result = await _client.post(
      '/institutions/${Uri.encodeComponent(organizationSlug)}/schools/$schoolId/academic/$route',
      draft.toJson(),
    );
    try {
      final bool matches;
      switch (draft.kind) {
        case AcademicKind.year:
          final item = AcademicYear.fromJson(
            enrollmentMap(result['academic_year']),
          );
          matches =
              item.schoolId == schoolId &&
              item.name == draft.name.trim() &&
              academicDateText(item.start) == academicDateText(draft.start!) &&
              academicDateText(item.end) == academicDateText(draft.end!) &&
              item.current == draft.current &&
              !current.years.any((y) => y.id == item.id);
          break;
        case AcademicKind.grade:
          final item = AcademicGrade.fromJson(enrollmentMap(result['grade']));
          matches =
              item.schoolId == schoolId &&
              item.name == draft.name.trim() &&
              !current.grades.any((g) => g.id == item.id);
          break;
        case AcademicKind.section:
          final raw = enrollmentMap(result['section']);
          final item = InstitutionAcademicSection.fromJson(raw);
          matches =
              (!raw.containsKey('school_id') || raw['school_id'] == schoolId) &&
              item.name == draft.name.trim() &&
              item.yearId == draft.yearId &&
              item.gradeId == draft.gradeId &&
              item.capacity == draft.capacity &&
              !current.sections.any((s) => s.id == item.id);
          break;
      }
      if (!matches)
        throw const FormatException('Academic receipt does not match request');
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
