import '../enrollment/enrollment_models.dart';

class SchoolTeacher {
  const SchoolTeacher(this.id, this.schoolId, this.name, this.active);
  final int id, schoolId;
  final String name;
  final bool active;
  factory SchoolTeacher.fromJson(Map<String, dynamic> data) {
    final name = enrollmentText(data['name']);
    if (data['role'] != 'teacher' ||
        data['is_active'] is! bool ||
        name.length > 120) {
      throw const FormatException('Invalid teacher');
    }
    return SchoolTeacher(
      enrollmentId(data['id']),
      enrollmentId(data['school_id']),
      name,
      data['is_active'] as bool,
    );
  }
}

class TeacherAssignment {
  const TeacherAssignment(
    this.id,
    this.schoolId,
    this.teacherId,
    this.sectionId,
    this.subjectId,
    this.version,
  );
  final int id, schoolId, teacherId, sectionId, subjectId, version;
  factory TeacherAssignment.fromJson(Map<String, dynamic> data) =>
      TeacherAssignment(
        enrollmentId(data['id']),
        enrollmentId(data['school_id']),
        enrollmentId(data['teacher_id']),
        enrollmentId(data['section_id']),
        enrollmentId(data['subject_id']),
        enrollmentId(data['version']),
      );
  String get identity => '$teacherId:$sectionId:$subjectId';
  bool sameRecord(TeacherAssignment other) =>
      id == other.id &&
      schoolId == other.schoolId &&
      version == other.version &&
      identity == other.identity;
}

class TeacherAssignmentDraft {
  const TeacherAssignmentDraft({
    required this.teacherId,
    required this.sectionId,
    required this.subjectId,
  });
  final int teacherId, sectionId, subjectId;
  bool get valid => teacherId > 0 && sectionId > 0 && subjectId > 0;
  String get identity => '$teacherId:$sectionId:$subjectId';
  Map<String, dynamic> toJson() => {
    'teacher_id': teacherId,
    'section_id': sectionId,
    'subject_id': subjectId,
  };
}
