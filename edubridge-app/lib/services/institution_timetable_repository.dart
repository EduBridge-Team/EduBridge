import '../model/enrollment/enrollment_models.dart';
import '../model/institutions/institution_timetable.dart';
import '../model/schools/academic_catalog.dart';
import 'enrollment/enrollment_api_client.dart';
import 'institution_academic_repository.dart';
import 'institution_teacher_assignments_repository.dart';

abstract interface class InstitutionTimetableGateway {
  Future<InstitutionTimetable> load();
  Future<InstitutionSubstituteChoices> available(int entryId, DateTime date);
  Future<InstitutionSubstitutionReceipt> assign(InstitutionSubstituteChoices expected, int teacherId, String? notes);
}
class InstitutionTimetableRepository implements InstitutionTimetableGateway {
  InstitutionTimetableRepository({required this.organizationSlug, required this.organizationId,
    required this.schoolId, EnrollmentApiClient? client}) : _client = client ?? EnrollmentApiClient();
  final String organizationSlug;
  final int organizationId, schoolId;
  final EnrollmentApiClient _client;
  String get _root => '/institutions/${Uri.encodeComponent(organizationSlug)}/schools/$schoolId/timetable';
  @override
  Future<InstitutionTimetable> load() async {
    final academic = await InstitutionAcademicRepository(organizationSlug: organizationSlug, schoolId: schoolId, client: _client).load();
    if (academic.organizationId != organizationId) throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    final data = await _client.get(_root);
    try {
      return InstitutionTimetable.fromJson(academic, data);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
  @override
  Future<InstitutionSubstituteChoices> available(int entryId, DateTime date) async {
    final timetable = await load();
    final entries = timetable.entries.where((e) => e.id == entryId);
    if (entries.length != 1) throw const EnrollmentApiException(EnrollmentFailure.unavailable);
    final entry = entries.single;
    if (!timetable.acceptsDate(entry, date)) throw const EnrollmentApiException(EnrollmentFailure.validation);
    final members = await InstitutionTeacherAssignmentsRepository(organizationSlug: organizationSlug,
      organizationId: organizationId, schoolId: schoolId, client: _client).load();
    final response = await _client.get('$_root/$entryId/available-substitutes?date=${academicDateText(date)}');
    try {
      final teachers = <int, String>{};
      for (final raw in enrollmentList(response['available_teachers'])) {
        final row = enrollmentMap(raw), id = enrollmentId(enrollmentMap(raw)['id']);
        if (teachers.containsKey(id) || !members.teachers.containsKey(id) || id == entry.teacherId ||
            timetable.entries.any((e) => e.teacherId == id && e.weekday == entry.weekday && e.period == entry.period)) {
          throw const FormatException('Invalid available substitute');
        }
        teachers[id] = enrollmentText(row['name']);
      }
      return InstitutionSubstituteChoices(timetable, entry, timetableDate(date), teachers);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
  @override
  Future<InstitutionSubstitutionReceipt> assign(InstitutionSubstituteChoices expected, int teacherId, String? notes) async {
    if (expected.timetable.academic.organizationSlug != organizationSlug ||
        expected.timetable.academic.organizationId != organizationId || expected.entry.schoolId != schoolId ||
        !expected.teachers.containsKey(teacherId) || (notes?.length ?? 0) > 2000) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await available(expected.entry.id, expected.date);
    if (current.entry.identity != expected.entry.identity || !current.teachers.containsKey(teacherId)) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    final result = await _client.post('$_root/${current.entry.id}/substitutions', {
      'class_date': academicDateText(current.date), 'substitute_teacher_id': teacherId, 'notes': notes,
    });
    late final int id;
    try {
      final row = enrollmentMap(result['substitution']);
      id = enrollmentId(row['id']);
      if (enrollmentId(row['timetable_entry_id']) != current.entry.id ||
          academicDate(row['class_date']) != current.date || row['original_teacher_id'] != current.entry.teacherId ||
          enrollmentId(row['substitute_teacher_id']) != teacherId || row['status'] != 'assigned' || row['notes'] != notes) {
        throw const FormatException('Mismatched substitution receipt');
      }
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    late final InstitutionSubstituteChoices after;
    try {
      after = await available(current.entry.id, current.date);
    } on EnrollmentApiException catch (e) {
      if (e.failure == EnrollmentFailure.session || e.failure == EnrollmentFailure.forbidden || e.failure == EnrollmentFailure.invalidResponse) rethrow;
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    }
    if (after.entry.identity != current.entry.identity || after.teachers.containsKey(teacherId)) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    return InstitutionSubstitutionReceipt(id, current.teachers[teacherId]!, current.date);
  }
}
