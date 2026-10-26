import '../enrollment/enrollment_models.dart';
import '../schools/academic_catalog.dart';
import '../schools/curriculum_catalog.dart';

/// The institution API scopes sections through their grade and year, not a
/// section.school_id field. A null capacity means it has not been specified.
class InstitutionAcademicSection {
  const InstitutionAcademicSection(
    this.id,
    this.name,
    this.yearId,
    this.gradeId,
    this.capacity,
    this.teacher,
  );
  final int id, yearId, gradeId;
  final int? capacity;
  final String name;
  final String? teacher;
  factory InstitutionAcademicSection.fromJson(Map<String, dynamic> data) {
    final capacity = data['capacity'];
    final teacher = data['homeroom_teacher_name'];
    if ((capacity != null &&
            (capacity is! int || capacity < 1 || capacity > 500)) ||
        (teacher != null && teacher is! String)) {
      throw const FormatException('Invalid section fields');
    }
    return InstitutionAcademicSection(
      enrollmentId(data['id']),
      enrollmentText(data['name']),
      enrollmentId(data['academic_year_id']),
      enrollmentId(data['grade_id']),
      capacity as int?,
      teacher as String?,
    );
  }
}

class InstitutionAcademicRecords {
  InstitutionAcademicRecords._(
    this.organizationSlug,
    this.school,
    this.curriculum,
    List<AcademicGrade> grades,
    List<InstitutionAcademicSection> sections,
  ) : grades = List.unmodifiable(grades),
      sections = List.unmodifiable(sections);
  final String organizationSlug;
  final EnrollmentSchool school;
  final CurriculumCatalog curriculum;
  final List<AcademicGrade> grades;
  final List<InstitutionAcademicSection> sections;
  factory InstitutionAcademicRecords.fromJson(
    String slug,
    int organizationId,
    int schoolId,
    Map<String, dynamic> data,
  ) {
    final school = enrollmentMap(data['school']);
    if (enrollmentId(school['id']) != schoolId ||
        enrollmentId(school['organization_id']) != organizationId) {
      throw const FormatException('Foreign school or institution');
    }
    // Terms have a year FK in this real API. The validated year relationship
    // supplies their school identity for the shared curriculum decoder.
    final terms = enrollmentList(data['academic_terms']).map((item) {
      final term = enrollmentMap(item);
      if (term.containsKey('school_id') && term['school_id'] != schoolId) {
        throw const FormatException('Foreign term school');
      }
      return {...term, 'school_id': schoolId};
    }).toList();
    final curriculum = CurriculumCatalog.fromJson({
      ...data,
      'academic_terms': terms,
    });
    final grades = enrollmentList(data['grades'])
        .map((item) => AcademicGrade.fromJson(enrollmentMap(item)))
        .toList();
    final sections = enrollmentList(data['sections']).map((item) {
      final section = enrollmentMap(item);
      if (section.containsKey('school_id') &&
          section['school_id'] != schoolId) {
        throw const FormatException('Foreign section school');
      }
      return InstitutionAcademicSection.fromJson(section);
    }).toList();
    final yearIds = curriculum.years.map((y) => y.id).toSet();
    final gradeIds = grades.map((g) => g.id).toSet();
    if (gradeIds.length != grades.length ||
        grades.any((g) => g.schoolId != schoolId) ||
        sections.map((s) => s.id).toSet().length != sections.length ||
        sections.any(
          (s) => !yearIds.contains(s.yearId) || !gradeIds.contains(s.gradeId),
        )) {
      throw const FormatException('Invalid academic relationships');
    }
    return InstitutionAcademicRecords._(
      slug,
      curriculum.school,
      curriculum,
      grades,
      sections,
    );
  }
}
