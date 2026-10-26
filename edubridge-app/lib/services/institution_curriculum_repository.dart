import '../model/enrollment/enrollment_models.dart';
import '../model/schools/academic_catalog.dart';
import '../model/schools/curriculum_catalog.dart';
import '../model/schools/curriculum_draft.dart';
import 'enrollment/enrollment_api_client.dart';
import 'institution_academic_repository.dart';
import 'schools/curriculum_repository.dart';

/// Adapts the existing institution endpoints to the shared curriculum editor.
class InstitutionCurriculumRepository implements CurriculumGateway {
  InstitutionCurriculumRepository({
    required this.organizationSlug,
    required this.schoolId,
    required int organizationId,
    EnrollmentApiClient? client,
  }) : _organizationId = organizationId,
       _client = client ?? EnrollmentApiClient();

  final String organizationSlug;
  final int schoolId;
  final EnrollmentApiClient _client;
  final int _organizationId;
  bool _loaded = false;

  @override
  Future<CurriculumCatalog> load() async {
    final records = await InstitutionAcademicRepository(
      organizationSlug: organizationSlug,
      schoolId: schoolId,
      client: _client,
    ).load();
    if (_organizationId != records.organizationId) {
      throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    }
    _loaded = true;
    return records.curriculum;
  }

  @override
  Future<void> create(int schoolId, CurriculumDraft draft) async {
    if (schoolId != this.schoolId || !draft.valid || !_loaded) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await load();
    if (!draft.validFor(current)) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    final term = draft.kind == CurriculumKind.term;
    final route = term ? 'years/${draft.yearId}/terms' : 'subjects';
    final body = draft.toJson()..remove('academic_year_id');
    final data = await _client.post(
      '/institutions/${Uri.encodeComponent(organizationSlug)}/schools/$schoolId/academic/$route',
      body,
    );
    try {
      final item = enrollmentMap(data[term ? 'term' : 'subject']);
      final bool matches;
      if (term) {
        // Institution terms are scoped through their year; the receipt may omit
        // school_id, but an explicitly foreign school must never be accepted.
        if (item.containsKey('school_id') && item['school_id'] != schoolId) {
          throw const FormatException('Foreign term school');
        }
        final saved = CurriculumTerm.fromJson({...item, 'school_id': schoolId});
        matches = saved.yearId == draft.yearId &&
            saved.name == draft.name.trim() &&
            saved.position == draft.position &&
            academicDateText(saved.start) == academicDateText(draft.start!) &&
            academicDateText(saved.end) == academicDateText(draft.end!) &&
            !current.terms.any((value) => value.id == saved.id);
      } else {
        final saved = CurriculumSubject.fromJson(item);
        matches = saved.schoolId == schoolId &&
            saved.name == draft.name.trim() &&
            saved.code == draft.normalizedCode &&
            saved.active == draft.active &&
            !current.subjects.any((value) => value.id == saved.id);
      }
      if (!matches) throw const FormatException('Curriculum receipt mismatch');
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
