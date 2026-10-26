import '../enrollment/enrollment_models.dart';
import '../schools/academic_catalog.dart';
import 'institution_academic_records.dart';

enum InstitutionEnrollmentStatus { active, withdrawn, transferred }

class InstitutionEnrollmentRecord {
  const InstitutionEnrollmentRecord(this.id, this.childId, this.childName,
      this.sectionId, this.status, this.start, this.end);
  final int id, childId, sectionId;
  final String childName;
  final InstitutionEnrollmentStatus status;
  final DateTime? start, end;
}

class InstitutionEnrollmentHistory {
  InstitutionEnrollmentHistory._(this.academic, List<InstitutionEnrollmentRecord> records)
      : records = List.unmodifiable(records);
  final InstitutionAcademicRecords academic;
  final List<InstitutionEnrollmentRecord> records;

  factory InstitutionEnrollmentHistory.fromJson(
    InstitutionAcademicRecords academic, Map<String, dynamic> data,
  ) {
    final ids = <int>{};
    final records = <InstitutionEnrollmentRecord>[];
    for (final raw in enrollmentList(data['enrollments'])) {
      final row = enrollmentMap(raw);
      final id = enrollmentId(row['id']);
      final sectionId = enrollmentId(row['section_id']);
      final sections = academic.sections.where((v) => v.id == sectionId);
      final statuses = InstitutionEnrollmentStatus.values.where((v) => v.name == row['status']);
      if (!ids.add(id) || sections.length != 1 || statuses.length != 1 ||
          enrollmentId(row['academic_year_id']) != sections.single.yearId ||
          !row.containsKey('enrolled_on') || !row.containsKey('left_on')) {
        throw const FormatException('Invalid enrollment scope');
      }
      final start = row['enrolled_on'] == null ? null : academicDate(row['enrolled_on']);
      final end = row['left_on'] == null ? null : academicDate(row['left_on']);
      if ((start != null && end != null && end.isBefore(start)) ||
          (statuses.single == InstitutionEnrollmentStatus.active && end != null)) {
        throw const FormatException('Invalid enrollment dates');
      }
      records.add(InstitutionEnrollmentRecord(
        id, enrollmentId(row['child_id']), enrollmentText(row['child_name']),
        sectionId, statuses.single, start, end,
      ));
    }
    records.sort((a, b) {
      if (a.start == null && b.start != null) return 1;
      if (a.start != null && b.start == null) return -1;
      final order = a.start == null ? 0 : b.start!.compareTo(a.start!);
      return order == 0 ? b.id.compareTo(a.id) : order;
    });
    return InstitutionEnrollmentHistory._(academic, records);
  }

  List<InstitutionAcademicSection> transferTargets(int enrollmentId) {
    final matches = records.where((r) => r.id == enrollmentId);
    if (matches.length != 1 || matches.single.status != InstitutionEnrollmentStatus.active) {
      return const [];
    }
    final record = matches.single;
    final source = academic.sections.firstWhere((s) => s.id == record.sectionId);
    final used = records.where((r) => r.childId == record.childId).map((r) => r.sectionId).toSet();
    return academic.sections.where((s) => s.yearId == source.yearId && !used.contains(s.id)).toList();
  }

  String sectionLabel(int id) {
    final section = academic.sections.firstWhere((v) => v.id == id);
    final year = academic.years.firstWhere((v) => v.id == section.yearId);
    final grade = academic.grades.firstWhere((v) => v.id == section.gradeId);
    return '${year.name} — ${grade.name} — ${section.name}';
  }
}
