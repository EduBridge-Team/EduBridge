import '../../model/enrollment/enrollment_models.dart';
import '../../model/schools/academic_catalog.dart';
import '../../model/schools/curriculum_catalog.dart';
import '../../model/schools/curriculum_draft.dart';
import '../enrollment/enrollment_api_client.dart';

abstract interface class CurriculumGateway {
  Future<CurriculumCatalog> load();
  Future<void> create(int schoolId, CurriculumDraft draft);
}

class CurriculumRepository implements CurriculumGateway {
  CurriculumRepository({EnrollmentApiClient? client})
    : _client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient _client;
  @override
  Future<CurriculumCatalog> load() async {
    final context = await _client.get('/school/context');
    final data = await _client.get('/school/academic/curriculum');
    try {
      final identity = SchoolPortalIdentity.fromJson(
        enrollmentMap(context['school']),
      );
      final catalog = CurriculumCatalog.fromJson(data);
      if (catalog.school.id != identity.school.id)
        throw const FormatException('Foreign school');
      return catalog;
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  @override
  Future<void> create(int schoolId, CurriculumDraft draft) async {
    if (schoolId < 1 || !draft.valid) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final route = draft.kind == CurriculumKind.term ? 'terms' : 'subjects';
    final data = await _client.post('/school/academic/$route', {
      ...draft.toJson(),
      'expected_school_id': schoolId,
    });
    try {
      if (enrollmentId(data['school_id']) != schoolId)
        throw const FormatException('Foreign receipt');
      final item = enrollmentMap(data['item']);
      final bool matches;
      if (draft.kind == CurriculumKind.term) {
        final term = CurriculumTerm.fromJson(item);
        matches =
            term.schoolId == schoolId &&
            term.name == draft.name.trim() &&
            term.yearId == draft.yearId &&
            term.position == draft.position &&
            academicDateText(term.start) == academicDateText(draft.start!) &&
            academicDateText(term.end) == academicDateText(draft.end!);
      } else {
        final subject = CurriculumSubject.fromJson(item);
        matches =
            subject.schoolId == schoolId &&
            subject.name == draft.name.trim() &&
            subject.code == draft.normalizedCode &&
            subject.active == draft.active;
      }
      if (!matches) throw const FormatException('Receipt mismatch');
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
