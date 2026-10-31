import '../enrollment/enrollment_models.dart';

DateTime academicDate(dynamic value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('Invalid date');
  }
  final date = DateTime.tryParse(value);
  if (date == null || academicDateText(date) != value) {
    throw const FormatException('Invalid calendar date');
  }
  return date;
}
String academicDateText(DateTime date) =>
    date.toIso8601String().substring(0, 10);
bool _boolean(dynamic value) {
  if (value is! bool) throw const FormatException('Expected boolean');
  return value;
}
String _name(dynamic value, int limit) {
  final name = enrollmentText(value);
  if (name.trim().length > limit) throw const FormatException('Name too long');
  return name;
}

class AcademicYear {
  const AcademicYear(this.id, this.schoolId, this.name, this.start, this.end, this.current);
  final int id, schoolId;
  final String name;
  final DateTime start, end;
  final bool current;
  factory AcademicYear.fromJson(Map<String, dynamic> data) {
    final start = academicDate(data['starts_on']);
    final end = academicDate(data['ends_on']);
    if (!end.isAfter(start)) throw const FormatException('Invalid year range');
    return AcademicYear(enrollmentId(data['id']), enrollmentId(data['school_id']),
        _name(data['name'], 40), start, end, _boolean(data['is_current']));
  }
}

class AcademicGrade {
  const AcademicGrade(this.id, this.schoolId, this.name);
  final int id, schoolId;
  final String name;
  factory AcademicGrade.fromJson(Map<String, dynamic> data) => AcademicGrade(
      enrollmentId(data['id']), enrollmentId(data['school_id']), _name(data['name'], 80));
}

class AcademicSection {
  const AcademicSection(this.id, this.schoolId, this.name, this.yearId, this.gradeId, this.capacity);
  final int id, schoolId, yearId, gradeId;
  final int? capacity;
  final String name;
  factory AcademicSection.fromJson(Map<String, dynamic> data) {
    final capacity = data['capacity'] == null ? null : enrollmentId(data['capacity']);
    if (capacity != null && capacity > 500) throw const FormatException('Invalid capacity');
    return AcademicSection(enrollmentId(data['id']), enrollmentId(data['school_id']),
        _name(data['name'], 80), enrollmentId(data['academic_year_id']),
        enrollmentId(data['grade_id']), capacity);
  }
}

/// Validated choices shared by academic authoring forms.
abstract interface class AcademicFormData {
  EnrollmentSchool get school;
  List<AcademicYear> get years;
  List<AcademicGrade> get grades;
}

class AcademicCatalog implements AcademicFormData {
  AcademicCatalog._(this.school, List<AcademicYear> years,
      List<AcademicGrade> grades, List<AcademicSection> sections)
      : years = List.unmodifiable(years), grades = List.unmodifiable(grades),
        sections = List.unmodifiable(sections);
  final EnrollmentSchool school;
  final List<AcademicYear> years;
  final List<AcademicGrade> grades;
  final List<AcademicSection> sections;
  factory AcademicCatalog.fromJson(Map<String, dynamic> data) {
    final school = EnrollmentSchool.fromJson(enrollmentMap(data['school']));
    final years = enrollmentList(data['academic_years'])
        .map((v) => AcademicYear.fromJson(enrollmentMap(v))).toList();
    final grades = enrollmentList(data['grades'])
        .map((v) => AcademicGrade.fromJson(enrollmentMap(v))).toList();
    final sections = enrollmentList(data['sections'])
        .map((v) => AcademicSection.fromJson(enrollmentMap(v))).toList();
    final yearIds = years.map((v) => v.id).toSet();
    final gradeIds = grades.map((v) => v.id).toSet();
    if (yearIds.length != years.length || gradeIds.length != grades.length ||
        sections.map((v) => v.id).toSet().length != sections.length ||
        years.where((v) => v.current).length > 1 ||
        years.any((v) => v.schoolId != school.id) ||
        grades.any((v) => v.schoolId != school.id) ||
        sections.any((v) => v.schoolId != school.id ||
            !yearIds.contains(v.yearId) || !gradeIds.contains(v.gradeId))) {
      throw const FormatException('Academic scope mismatch');
    }
    years.sort((a, b) => b.start.compareTo(a.start));
    return AcademicCatalog._(school, years, grades, sections);
  }
}

enum AcademicKind { year, grade, section }

class AcademicDraft {
  const AcademicDraft({
    required this.kind, required this.name, this.start, this.end,
    this.current = false, this.yearId, this.gradeId, this.capacity,
  });
  final AcademicKind kind;
  final String name;
  final DateTime? start, end;
  final bool current;
  final int? yearId, gradeId, capacity;
  bool get valid {
    if (name.trim().isEmpty || name.trim().length > (kind == AcademicKind.year ? 40 : 80)) {
      return false;
    }
    return switch (kind) {
      AcademicKind.year => start != null && end != null && end!.isAfter(start!),
      AcademicKind.grade => true,
      AcademicKind.section => (yearId ?? 0) > 0 && (gradeId ?? 0) > 0 &&
          (capacity ?? 0) > 0 && capacity! <= 500,
    };
  }
  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    if (kind == AcademicKind.year) ...{
      'starts_on': academicDateText(start!), 'ends_on': academicDateText(end!),
      'is_current': current,
    },
    if (kind == AcademicKind.section) ...{
      'academic_year_id': yearId, 'grade_id': gradeId, 'capacity': capacity,
    },
  };
}
