import '../enrollment/enrollment_models.dart';
import '../schools/academic_catalog.dart';

int? _count(dynamic value) {
  if (value == null) return null;
  if (value is! int || value < 0) throw const FormatException('Invalid statistic');
  return value;
}
class InstitutionSchoolStatistics {
  InstitutionSchoolStatistics(this.id, this.name, Map<String, int?> counts, Map<String, int?> attendance)
    : counts = Map.unmodifiable(counts), attendance = Map.unmodifiable(attendance);
  final int id;
  final String name;
  final Map<String, int?> counts, attendance;
}
class InstitutionStatistics {
  InstitutionStatistics(this.organizationId, this.organizationSlug, Map<String, int?> summary,
    List<InstitutionSchoolStatistics> schools, this.loadedAt, {Map<String, int?> periodSummary = const {}})
    : summary = Map.unmodifiable(summary), schools = List.unmodifiable(schools), periodSummary = Map.unmodifiable(periodSummary);
  final int organizationId;
  final String organizationSlug;
  final Map<String, int?> summary, periodSummary;
  final List<InstitutionSchoolStatistics> schools;
  final DateTime loadedAt;
  int? attendanceTotal(String status) {
    if (schools.any((school) => school.attendance[status] == null)) return null;
    return schools.fold<int>(0, (sum, school) => sum + school.attendance[status]!);
  }
  double? get presentRate {
    final counts = [for (final status in ['present', 'absent', 'late', 'excused']) attendanceTotal(status)];
    if (counts.any((count) => count == null)) return null;
    final total = counts.fold<int>(0, (sum, count) => sum + count!);
    return total == 0 ? null : counts.first! * 100 / total;
  }
  factory InstitutionStatistics.fromJson(int organizationId, String slug, Map<String, dynamic> data, {DateTime? from, DateTime? to}) {
    if (data['success'] == false || data['error'] != null) {
      throw const FormatException('Rejected statistics response');
    }
    // Optional response identity must never contradict the authenticated context.
    if ((data.containsKey('organization_id') && enrollmentId(data['organization_id']) != organizationId) ||
        (data.containsKey('organization_slug') && data['organization_slug'] != slug)) {
      throw const FormatException('Statistics organization scope mismatch');
    }
    final rawSummary = enrollmentMap(data['summary']);
    final summary = {for (final key in ['schools', 'student_files', 'specialists', 'teachers', 'active_teachers', 'active_enrollments', 'attendance_sessions'])
      key: _count(rawSummary[key])};
    final schools = <InstitutionSchoolStatistics>[];
    final ids = <int>{};
    for (final raw in enrollmentList(data['schools'])) {
      final row = enrollmentMap(raw), id = enrollmentId(enrollmentMap(raw)['school_id']);
      if (!ids.add(id)) throw const FormatException('Duplicate school');
      final attendance = row['attendance'] == null ? <String, dynamic>{} : enrollmentMap(row['attendance']);
      schools.add(InstitutionSchoolStatistics(id, enrollmentText(row['school_name']),
        {for (final key in ['sections', 'active_enrollments', 'timetable_entries', 'attendance_sessions']) key: _count(row[key])},
        {for (final key in ['present', 'absent', 'late', 'excused']) key: _count(attendance[key])}));
    }
    if (summary['schools'] != null && summary['schools'] != schools.length) {
      throw const FormatException('School count mismatch');
    }
    for (final key in ['active_enrollments', 'attendance_sessions']) {
      if (summary[key] != null && schools.every((s) => s.counts[key] != null) &&
          summary[key] != schools.fold<int>(0, (total, s) => total + s.counts[key]!)) {
        throw const FormatException('School totals mismatch');
      }
    }
    // A supplied period must match the requested window even when period counters
    // are unavailable. Never attribute a report for another window to this one.
    if (data['period'] != null) {
      final period = enrollmentMap(data['period']);
      if (from == null || to == null || academicDate(period['from']) != from ||
          academicDate(period['to']) != to) {
        throw const FormatException('Mismatched statistics period');
      }
    }
    final periodSummary = <String, int?>{};
    if (data['period_summary'] != null) {
      if (data['period'] == null) throw const FormatException('Missing statistics period');
      final values = enrollmentMap(data['period_summary']);
      for (final key in ['schools_created', 'teachers_joined', 'specialists_joined', 'student_files_created', 'enrollments_started']) {
        periodSummary[key] = _count(values[key]);
      }
    }
    return InstitutionStatistics(organizationId, slug, summary, schools, DateTime.now(), periodSummary: periodSummary);
  }
}
