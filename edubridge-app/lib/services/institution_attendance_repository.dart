import '../model/institutions/institution_attendance.dart';
import '../model/institutions/institution_attendance_draft.dart';
import '../model/institutions/institution_enrollment_history.dart';
import '../model/enrollment/enrollment_models.dart';
import 'institution_enrollment_history_repository.dart';
import '../model/schools/academic_catalog.dart';
import 'enrollment/enrollment_api_client.dart';
import 'institution_academic_repository.dart';

abstract interface class InstitutionAttendanceGateway {
  Future<InstitutionAttendanceView> load({DateTime? date, int? sessionId});
}

abstract interface class InstitutionAttendanceWriter implements InstitutionAttendanceGateway {
  Future<int> createAttendance(AttendanceSessionDraft draft);
  Future<AttendanceEditorData> loadEditor({required int sessionId, required DateTime date});
  Future<void> saveAttendance(AttendanceEditorData expected, Map<int, AttendanceMark> marks, {required bool closeSession});
}

class InstitutionAttendanceRepository implements InstitutionAttendanceWriter {
  InstitutionAttendanceRepository({required this.organizationSlug, required this.organizationId,
    required this.schoolId, EnrollmentApiClient? client}) : _client = client ?? EnrollmentApiClient();
  final String organizationSlug;
  final int organizationId, schoolId;
  final EnrollmentApiClient _client;
  String get _root => '/institutions/${Uri.encodeComponent(organizationSlug)}/schools/$schoolId/attendance';

  Future<T> _verify<T>(Future<T> Function() read) async {
    try {
      return await read();
    } on EnrollmentApiException catch (e) {
      if (e.failure == EnrollmentFailure.session || e.failure == EnrollmentFailure.forbidden ||
          e.failure == EnrollmentFailure.invalidResponse || e.failure == EnrollmentFailure.unavailable) rethrow;
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    }
  }

  @override
  Future<int> createAttendance(AttendanceSessionDraft draft) async {
    if (!draft.valid) throw const EnrollmentApiException(EnrollmentFailure.validation);
    final before = await load(date: draft.date);
    if (!before.academic.sections.any((s) => s.id == draft.sectionId) ||
        (draft.subjectId != null && !before.academic.curriculum.subjects.any((s) => s.id == draft.subjectId && s.active))) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    if (before.sessions.any((s) => s.sectionId == draft.sectionId && s.period == draft.period)) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    final response = await _client.post(_root, draft.toJson());
    late final InstitutionAttendanceSession session;
    final count = response['students_initialized'];
    try {
      session = InstitutionAttendanceSession.fromJson(before.academic, enrollmentMap(response['attendance_session']));
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    if (session.sectionId != draft.sectionId || session.subjectId != draft.subjectId ||
        academicDateText(session.date) != academicDateText(draft.date) || session.period != draft.period ||
        session.note != draft.note || session.closed || count is! int || count < 0 ||
        before.sessions.any((s) => s.id == session.id)) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    final after = await _verify(() => load(date: draft.date, sessionId: session.id));
    if (after.session!.sectionId != draft.sectionId || after.session!.subjectId != draft.subjectId ||
        after.session!.period != draft.period || after.session!.note != draft.note || after.records.length != count) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    return session.id;
  }

  @override
  Future<AttendanceEditorData> loadEditor({required int sessionId, required DateTime date}) async {
    final view = await load(sessionId: sessionId, date: date);
    final history = await InstitutionEnrollmentHistoryRepository(organizationSlug: organizationSlug,
      organizationId: organizationId, schoolId: schoolId, client: _client).load();
    final active = history.records.where((r) => r.sectionId == view.session!.sectionId &&
      r.status == InstitutionEnrollmentStatus.active).toList();
    if (active.map((r) => r.childId).toSet().length != active.length) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    return AttendanceEditorData(view, active.map((child) {
      final records = view.records.where((r) => r.childId == child.childId);
      return AttendanceStudent(child.childId, child.childName, records.isEmpty ? null : records.single);
    }).toList());
  }

  @override
  Future<void> saveAttendance(AttendanceEditorData expected, Map<int, AttendanceMark> marks, {required bool closeSession}) async {
    final session = expected.view.session;
    if (session == null || expected.view.academic.organizationId != organizationId ||
        expected.view.academic.organizationSlug != organizationSlug || expected.view.academic.school.id != schoolId ||
        marks.isEmpty || marks.length > 500 || marks.values.any((m) => !m.valid)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await loadEditor(sessionId: session.id, date: session.date);
    final fresh = current.view.session!;
    final ids = current.students.map((s) => s.id).toSet();
    if (fresh.closed || fresh.sectionId != session.sectionId ||
        marks.length != ids.length || !marks.keys.every(ids.contains) ||
        current.students.length != expected.students.length) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    for (final student in current.students) {
      final previous = expected.students.where((s) => s.id == student.id);
      if (previous.length != 1 || previous.single.record?.status != student.record?.status ||
          (previous.single.record?.note ?? '') != (student.record?.note ?? '')) {
        throw const EnrollmentApiException(EnrollmentFailure.conflict);
      }
    }
    final response = await _client.put('$_root/${session.id}/records', {
      'records': [for (final entry in marks.entries) entry.value.toJson(entry.key)],
      'close_session': closeSession,
    });
    if (response['message'] is! String || (response['message'] as String).isEmpty) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    final after = await _verify(() => load(sessionId: session.id, date: session.date));
    if (after.session!.closed != closeSession || after.session!.sectionId != session.sectionId) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    for (final entry in marks.entries) {
      final records = after.records.where((r) => r.childId == entry.key);
      if (records.length != 1 || records.single.status != entry.value.status ||
          (records.single.note ?? '') != (entry.value.note ?? '')) {
        throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
      }
    }
  }

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
