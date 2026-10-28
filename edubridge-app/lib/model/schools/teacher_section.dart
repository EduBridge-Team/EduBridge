import '../enrollment/enrollment_models.dart';

class TeacherSection {
  TeacherSection._(this.id, this.schoolId, this.yearId, this.name, this.schoolName, this.yearName,
    Map<int, String> subjects) : subjects = Map.unmodifiable(subjects);
  final int id, schoolId, yearId;
  final String name, schoolName, yearName;
  final Map<int, String> subjects;
  factory TeacherSection.fromJson(Map<String, dynamic> data) {
    final subjects = <int, String>{};
    for (final item in enrollmentList(data['subjects'])) {
      final subject = enrollmentMap(item), id = enrollmentId(subject['subject_id']);
      if (subjects.containsKey(id)) throw const FormatException('Duplicate section subject');
      subjects[id] = enrollmentText(subject['name']);
    }
    return TeacherSection._(enrollmentId(data['section_id']), enrollmentId(data['school_id']),
      enrollmentId(data['academic_year_id']), enrollmentText(data['section_name']),
      enrollmentText(data['school_name']), enrollmentText(data['academic_year_name']), subjects);
  }
  String get label => '$schoolName / $yearName / $name';
}

class TeacherSectionCatalog {
  TeacherSectionCatalog._(List<TeacherSection> sections) : sections = List.unmodifiable(sections);
  final List<TeacherSection> sections;
  factory TeacherSectionCatalog.fromJson(Map<String, dynamic> data) {
    if (data['contract_version'] != 1) throw const FormatException('Unsupported teacher sections');
    final sections = enrollmentList(data['sections']).map((s) => TeacherSection.fromJson(enrollmentMap(s))).toList();
    if (sections.map((s) => s.id).toSet().length != sections.length) throw const FormatException('Duplicate section');
    return TeacherSectionCatalog._(sections);
  }
}

class TeacherSectionRoster {
  TeacherSectionRoster._(List<Map<String, dynamic>> students) : students = List.unmodifiable(students);
  final List<Map<String, dynamic>> students;
  factory TeacherSectionRoster.fromJson(Map<String, dynamic> data, TeacherSection section) {
    if (data['contract_version'] != 1 || data['section_id'] != section.id ||
        data['school_id'] != section.schoolId || data['academic_year_id'] != section.yearId) {
      throw const FormatException('Foreign section roster');
    }
    final students = <Map<String, dynamic>>[];
    for (final item in enrollmentList(data['students'])) {
      final child = enrollmentMap(item), progress = child['progress_percentage'];
      if (progress != null && (progress is! num || !progress.isFinite || progress < 0 || progress > 100)) {
        throw const FormatException('Invalid student progress');
      }
      if (child['status'] != null && child['status'] is! String) throw const FormatException('Invalid student status');
      students.add(Map.unmodifiable({'id': enrollmentId(child['id']), 'name': enrollmentText(child['name']),
        if (progress != null) 'progress_percentage': progress, if (child['status'] != null) 'status': child['status']}));
    }
    if (students.map((s) => s['id']).toSet().length != students.length) throw const FormatException('Duplicate roster student');
    return TeacherSectionRoster._(students);
  }
}
