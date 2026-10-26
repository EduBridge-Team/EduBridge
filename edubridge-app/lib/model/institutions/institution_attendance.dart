import '../enrollment/enrollment_models.dart';
import '../schools/academic_catalog.dart';
import 'institution_academic_records.dart';

enum InstitutionAttendanceStatus { present, absent, late, excused }

String? attendanceNote(dynamic value) {
  if (value == null) return null;
  if (value is! String || value.length > 2000) {
    throw const FormatException('Invalid attendance note');
  }
  return value;
}

class InstitutionAttendanceSession {
  const InstitutionAttendanceSession(this.id, this.sectionId, this.subjectId,
    this.date, this.period, this.closed, this.note);
  final int id, sectionId;
  final int? subjectId, period;
  final DateTime date;
  final bool closed;
  final String? note;

  factory InstitutionAttendanceSession.fromJson(
    InstitutionAcademicRecords academic, Map<String, dynamic> row,
  ) {
    final section = enrollmentId(row['section_id']);
    final subject = row['subject_id'] == null ? null : enrollmentId(row['subject_id']);
    final period = row['period_number'];
    if (!academic.sections.any((s) => s.id == section) ||
        (subject != null && !academic.curriculum.subjects.any((s) => s.id == subject)) ||
        (period != null && (period is! int || period < 1 || period > 20)) ||
        !['open', 'closed'].contains(row['status'])) {
      throw const FormatException('Invalid attendance session scope');
    }
    return InstitutionAttendanceSession(enrollmentId(row['id']), section, subject,
      academicDate(row['attendance_date']), period as int?, row['status'] == 'closed',
      attendanceNote(row['notes']));
  }
}

class InstitutionAttendanceRecord {
  const InstitutionAttendanceRecord(this.id, this.childId, this.childName, this.status, this.note);
  final int id, childId;
  final String childName;
  final InstitutionAttendanceStatus status;
  final String? note;
  factory InstitutionAttendanceRecord.fromJson(int sessionId, Map<String, dynamic> row) {
    final statuses = InstitutionAttendanceStatus.values.where((s) => s.name == row['status']);
    if (enrollmentId(row['attendance_session_id']) != sessionId || statuses.length != 1) {
      throw const FormatException('Invalid attendance record scope');
    }
    return InstitutionAttendanceRecord(enrollmentId(row['id']), enrollmentId(row['child_id']),
      enrollmentText(row['child_name']), statuses.single, attendanceNote(row['note']));
  }
}

class InstitutionAttendanceView {
  InstitutionAttendanceView(this.academic, List<InstitutionAttendanceSession> sessions,
    {this.session, List<InstitutionAttendanceRecord> records = const []})
    : sessions = List.unmodifiable(sessions), records = List.unmodifiable(records);
  final InstitutionAcademicRecords academic;
  final List<InstitutionAttendanceSession> sessions;
  final InstitutionAttendanceSession? session;
  final List<InstitutionAttendanceRecord> records;

  factory InstitutionAttendanceView.fromJson(InstitutionAcademicRecords academic,
    Map<String, dynamic> data, {DateTime? date}) {
    final sessions = enrollmentList(data['attendance_sessions'])
      .map((r) => InstitutionAttendanceSession.fromJson(academic, enrollmentMap(r))).toList();
    if (sessions.length > 200 || sessions.map((s) => s.id).toSet().length != sessions.length ||
        (date != null && sessions.any((s) => academicDateText(s.date) != academicDateText(date)))) {
      throw const FormatException('Invalid attendance session list');
    }
    sessions.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate == 0 ? (a.period ?? 0).compareTo(b.period ?? 0) : byDate;
    });
    return InstitutionAttendanceView(academic, sessions);
  }

  InstitutionAttendanceView withDetail(int id, Map<String, dynamic> data) {
    final expected = sessions.singleWhere((s) => s.id == id);
    final detail = InstitutionAttendanceSession.fromJson(academic, enrollmentMap(data['attendance_session']));
    if (detail.id != id || detail.sectionId != expected.sectionId || detail.subjectId != expected.subjectId ||
        detail.date != expected.date || detail.period != expected.period) {
      throw const FormatException('Attendance session changed');
    }
    final records = enrollmentList(data['records'])
      .map((r) => InstitutionAttendanceRecord.fromJson(id, enrollmentMap(r))).toList();
    if (records.map((r) => r.id).toSet().length != records.length ||
        records.map((r) => r.childId).toSet().length != records.length) {
      throw const FormatException('Duplicate attendance records');
    }
    return InstitutionAttendanceView(academic, sessions, session: detail, records: records);
  }

  String sectionLabel(InstitutionAttendanceSession session) {
    final section = academic.sections.firstWhere((s) => s.id == session.sectionId);
    final grade = academic.grades.firstWhere((g) => g.id == section.gradeId);
    final year = academic.years.firstWhere((y) => y.id == section.yearId);
    return '${year.name} — ${grade.name} — ${section.name}';
  }
  String? subjectLabel(InstitutionAttendanceSession session) => session.subjectId == null ? null
    : academic.curriculum.subjects.firstWhere((s) => s.id == session.subjectId).name;
}
