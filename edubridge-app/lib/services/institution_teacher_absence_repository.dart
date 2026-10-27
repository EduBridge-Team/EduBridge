import '../model/enrollment/enrollment_models.dart';
import '../model/institutions/institution_teacher_absence.dart';
import '../model/institutions/institution_timetable.dart';
import '../model/institutions/institution_timetable_draft.dart';
import '../model/schools/academic_catalog.dart';
import 'enrollment/enrollment_api_client.dart';

abstract interface class InstitutionTeacherAbsenceGateway {
  Future<TimetableCreationData> loadAbsenceData();
  Future<InstitutionTeacherAbsenceReceipt> reportAbsence(int teacherId, DateTime date, String? reason);
}

class InstitutionTeacherAbsenceRepository implements InstitutionTeacherAbsenceGateway {
  InstitutionTeacherAbsenceRepository({required this.schoolId, required this.path,
    required this.client, required this.loadData});
  final int schoolId;
  final String path;
  final EnrollmentApiClient client;
  final Future<TimetableCreationData> Function() loadData;
  @override
  Future<TimetableCreationData> loadAbsenceData() => loadData();
  @override
  Future<InstitutionTeacherAbsenceReceipt> reportAbsence(int teacherId, DateTime date, String? reason) async {
    if (teacherId <= 0 || (reason?.length ?? 0) > 2000) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await loadData();
    if (!current.teachers.containsKey(teacherId)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final day = timetableDate(date);
    final response = await client.post(path, {'teacher_id': teacherId,
      'absence_date': academicDateText(day), 'reason': reason});
    try {
      final row = enrollmentMap(response['absence']);
      final id = enrollmentId(row['id']);
      if (enrollmentId(row['school_id']) != schoolId || enrollmentId(row['teacher_id']) != teacherId ||
          academicDate(row['absence_date']) != day || row['status'] != 'confirmed' || row['reason'] != reason) {
        throw const FormatException('Mismatched absence receipt');
      }
      final affected = enrollmentList(response['affected_classes']).map((raw) =>
        InstitutionTimetableEntry.fromJson(current.timetable.academic,
          {...enrollmentMap(raw), 'teacher_name': current.teachers[teacherId]})).toList();
      final expected = current.timetable.entries.where((e) => e.teacherId == teacherId && e.weekday == institutionWeekday(day)).toList();
      if (affected.length != expected.length ||
          affected.any((e) => !expected.any((v) => v.identity == e.identity)) ||
          affected.map((e) => e.id).toSet().length != affected.length ||
          affected.any((e) => e.teacherId != teacherId || e.weekday != institutionWeekday(day))) {
        throw const FormatException('Invalid affected classes');
      }
      // The API includes recurring slots from every year; retain them in the
      // receipt, but only offer substitution inside each slot's academic year.
      return InstitutionTeacherAbsenceReceipt(id, teacherId, current.teachers[teacherId]!,
        day, reason, current.timetable, affected);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
