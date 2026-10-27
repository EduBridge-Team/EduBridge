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
  factory InstitutionStatistics.fromJson(int organizationId, String slug, Map<String, dynamic> data, {DateTime? from, DateTime? to}) {
    final rawSummary = enrollmentMap(data['summary']);
    final summary = {for (final key in ['schools', 'student_files', 'active_teachers', 'active_enrollments', 'attendance_sessions'])
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
    final periodSummary = <String, int?>{};
    if (data['period_summary'] != null) {
      final period = enrollmentMap(data['period']);
      if (from == null || to == null || academicDate(period['from']) != from || academicDate(period['to']) != to) {
        throw const FormatException('Mismatched statistics period');
      }
      final values = enrollmentMap(data['period_summary']);
      for (final key in ['schools_created', 'teachers_joined', 'specialists_joined', 'student_files_created', 'enrollments_started']) {
        periodSummary[key] = _count(values[key]);
      }
    }
    return InstitutionStatistics(organizationId, slug, summary, schools, DateTime.now(), periodSummary: periodSummary);
  }
}
