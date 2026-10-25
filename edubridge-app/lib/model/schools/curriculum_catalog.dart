import '../enrollment/enrollment_models.dart';
import 'academic_catalog.dart';

String curriculumName(dynamic value, int max) {
  final name = enrollmentText(value).trim();
  if (name.length > max) throw const FormatException('Name too long');
  return name;
}

class CurriculumTerm {
  const CurriculumTerm(
    this.id,
    this.schoolId,
    this.yearId,
    this.name,
    this.position,
    this.start,
    this.end,
  );
  final int id, schoolId, yearId, position;
  final String name;
  final DateTime start, end;
  factory CurriculumTerm.fromJson(Map<String, dynamic> data) {
    final start = academicDate(data['starts_on']);
    final end = academicDate(data['ends_on']);
    final position = enrollmentId(data['position']);
    if (!end.isAfter(start) || position > 20) {
      throw const FormatException('Invalid term');
    }
    return CurriculumTerm(
      enrollmentId(data['id']),
      enrollmentId(data['school_id']),
      enrollmentId(data['academic_year_id']),
      curriculumName(data['name'], 60),
      position,
      start,
      end,
    );
  }
}

class CurriculumSubject {
  const CurriculumSubject(
    this.id,
    this.schoolId,
    this.name,
    this.code,
    this.active,
  );
  final int id, schoolId;
  final String name;
  final String? code;
  final bool active;
  factory CurriculumSubject.fromJson(Map<String, dynamic> data) {
    if (data['is_active'] is! bool || !data.containsKey('code')) {
      throw const FormatException('Missing subject fields');
    }
    return CurriculumSubject(
      enrollmentId(data['id']),
      enrollmentId(data['school_id']),
      curriculumName(data['name'], 120),
      data['code'] == null ? null : curriculumName(data['code'], 40),
      data['is_active'] as bool,
    );
  }
}

class CurriculumCatalog {
  CurriculumCatalog._(
    this.school,
    List<AcademicYear> years,
    List<CurriculumTerm> terms,
    List<CurriculumSubject> subjects,
  ) : years = List.unmodifiable(years),
      terms = List.unmodifiable(terms),
      subjects = List.unmodifiable(subjects);
  final EnrollmentSchool school;
  final List<AcademicYear> years;
  final List<CurriculumTerm> terms;
  final List<CurriculumSubject> subjects;
  factory CurriculumCatalog.fromJson(Map<String, dynamic> data) {
    final school = EnrollmentSchool.fromJson(enrollmentMap(data['school']));
    final years = enrollmentList(data['academic_years'])
        .map((v) => AcademicYear.fromJson(enrollmentMap(v)))
        .toList();
    final terms = enrollmentList(data['academic_terms'])
        .map((v) => CurriculumTerm.fromJson(enrollmentMap(v)))
        .toList();
    final subjects = enrollmentList(data['subjects'])
        .map((v) => CurriculumSubject.fromJson(enrollmentMap(v)))
        .toList();
    final byYear = {for (final year in years) year.id: year};
    final positions = <String>{};
    if (byYear.length != years.length ||
        years.where((v) => v.current).length > 1 ||
        terms.map((v) => v.id).toSet().length != terms.length ||
        subjects.map((v) => v.id).toSet().length != subjects.length ||
        years.any((v) => v.schoolId != school.id) ||
        subjects.any((v) => v.schoolId != school.id)) {
      throw const FormatException('Invalid curriculum scope');
    }
    for (final term in terms) {
      final year = byYear[term.yearId];
      if (term.schoolId != school.id ||
          year == null ||
          term.start.isBefore(year.start) ||
          term.end.isAfter(year.end) ||
          !positions.add('${term.yearId}:${term.position}')) {
        throw const FormatException('Invalid term scope or range');
      }
    }
    years.sort((a, b) => b.start.compareTo(a.start));
    terms.sort((a, b) => a.position.compareTo(b.position));
    return CurriculumCatalog._(school, years, terms, subjects);
  }
}
