import '../enrollment/enrollment_models.dart';
import 'institution_academic_records.dart';

const attendanceReportStatuses = ['present', 'absent', 'late', 'excused'];
int _count(dynamic value) {
  // PostgreSQL aggregate columns may be returned as decimal strings by PDO.
  final result = value is int ? value : value is String && RegExp(r'^\d+$').hasMatch(value) ? int.tryParse(value) : null;
  if (result == null || result < 0) throw const FormatException('Invalid attendance count');
  return result;
}
class AttendanceReportStudent {
  AttendanceReportStudent(this.id, this.name, this.total, Map<String, int> counts, this.rate)
    : counts = Map.unmodifiable(counts);
  final int id, total;
  final String name;
  final Map<String, int> counts;
  final double? rate;
  factory AttendanceReportStudent.fromJson(Map<String, dynamic> row) {
    final counts = {for (final s in attendanceReportStatuses) s: _count(row['${s}_count'])};
    final total = _count(row['total_sessions']), rate = row['attendance_rate'];
    if (counts.values.fold(0, (a, b) => a + b) != total || rate is! num || !rate.isFinite ||
        rate < 0 || rate > 100 || (rate - (total == 0 ? 0 : counts['present']! * 100 / total)).abs() > 0.051) {
      throw const FormatException('Inconsistent attendance totals');
    }
    return AttendanceReportStudent(enrollmentId(row['child_id']), enrollmentText(row['child_name']), total,
      counts, total == 0 ? null : rate.toDouble());
  }
}
class InstitutionAttendanceReport {
  InstitutionAttendanceReport(this.academic, Map<String, int> summary, List<AttendanceReportStudent> students,
    {this.from, this.to, this.sectionId}) : summary = Map.unmodifiable(summary), students = List.unmodifiable(students);
  final InstitutionAcademicRecords academic;
  final Map<String, int> summary;
  final List<AttendanceReportStudent> students;
  final DateTime? from, to;
  final int? sectionId;
  factory InstitutionAttendanceReport.fromJson(InstitutionAcademicRecords academic, Map<String, dynamic> data,
      {DateTime? from, DateTime? to, int? sectionId}) {
    final raw = enrollmentMap(data['summary']);
    final summary = {for (final s in attendanceReportStatuses) s: _count(raw[s])};
    final students = enrollmentList(data['students']).map((r) => AttendanceReportStudent.fromJson(enrollmentMap(r))).toList();
    if (students.map((s) => s.id).toSet().length != students.length || attendanceReportStatuses.any((status) =>
        students.fold(0, (total, s) => total + s.counts[status]!) != summary[status])) {
      throw const FormatException('Inconsistent attendance report');
    }
    return InstitutionAttendanceReport(academic, summary, students, from: from, to: to, sectionId: sectionId);
  }
}
