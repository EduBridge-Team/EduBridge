import '../enrollment/enrollment_models.dart';

class SpecialistSchool {
  const SpecialistSchool._(this.id, this.organizationId, this.assignmentId, this.name);
  final int id, organizationId, assignmentId;
  final String name;
  factory SpecialistSchool.fromJson(Map<String, dynamic> data) => SpecialistSchool._(
    enrollmentId(data['school_id']), enrollmentId(data['organization_id']),
    enrollmentId(data['assignment_id']), enrollmentText(data['school_name']));
  bool sameScope(SpecialistSchool other) => id == other.id &&
      organizationId == other.organizationId && assignmentId == other.assignmentId;
}
class SpecialistSchoolDirectory {
  SpecialistSchoolDirectory._(this.specialistId, List<SpecialistSchool> schools)
      : schools = List.unmodifiable(schools);
  final int specialistId;
  final List<SpecialistSchool> schools;
  factory SpecialistSchoolDirectory.fromJson(int expected, Map<String, dynamic> data) {
    if (data['contract_version'] != 1 || data['complete'] != true ||
        enrollmentId(data['specialist_id']) != expected) throw const FormatException('Invalid specialist scope');
    final schools = enrollmentList(data['schools']).map((item) =>
      SpecialistSchool.fromJson(enrollmentMap(item))).toList();
    if (schools.map((s) => s.id).toSet().length != schools.length ||
        schools.map((s) => s.assignmentId).toSet().length != schools.length) {
      throw const FormatException('Duplicate school assignment');
    }
    return SpecialistSchoolDirectory._(expected, schools);
  }
}
class SpecialistSchoolStudent {
  const SpecialistSchoolStudent._(this.id, this.enrollmentId, this.sectionId,
      this.yearId, this.name, this.sectionName, this.yearName,
      this.following, this.followupId, this.canFollow);
  final int id, enrollmentId, sectionId, yearId;
  final String name, sectionName, yearName;
  final bool following, canFollow;
  final int? followupId;
  factory SpecialistSchoolStudent.fromJson(Map<String, dynamic> data) {
    if (data['is_following'] is! bool || data['can_follow'] is! bool ||
        !data.containsKey('followup_id') ||
        (data['is_following'] == true && (data['can_follow'] == true || data['followup_id'] == null)) ||
        (data['is_following'] == false && data['followup_id'] != null)) {
      throw const FormatException('Invalid follow-up state');
    }
    return SpecialistSchoolStudent._(
      _id(data['child_id']), _id(data['enrollment_id']), _id(data['section_id']),
      _id(data['academic_year_id']), enrollmentText(data['name']),
      enrollmentText(data['section_name']), enrollmentText(data['academic_year_name']),
      data['is_following'] as bool,
      data['followup_id'] == null ? null : _id(data['followup_id']),
      data['can_follow'] as bool);
  }
  static int _id(dynamic value) => enrollmentIdValue(value);
  bool sameEnrollment(SpecialistSchoolStudent other) => id == other.id &&
      enrollmentId == other.enrollmentId && sectionId == other.sectionId && yearId == other.yearId;
}
// Avoid shadowing the enrollmentId parser with the student's enrollment field.
int enrollmentIdValue(dynamic value) => enrollmentId(value);

class SpecialistSchoolRoster {
  SpecialistSchoolRoster._(this.specialistId, this.school, this.revision,
      List<SpecialistSchoolStudent> students) : students = List.unmodifiable(students);
  final int specialistId;
  final SpecialistSchool school;
  final String revision;
  final List<SpecialistSchoolStudent> students;
  factory SpecialistSchoolRoster.fromJson(int expected, SpecialistSchool school, Map<String, dynamic> data) {
    if (data['contract_version'] != 1 || data['complete'] != true ||
        enrollmentId(data['specialist_id']) != expected ||
        enrollmentId(data['school_id']) != school.id ||
        enrollmentId(data['organization_id']) != school.organizationId ||
        enrollmentId(data['assignment_id']) != school.assignmentId) {
      throw const FormatException('Invalid school roster scope');
    }
    final students = enrollmentList(data['students']).map((item) =>
      SpecialistSchoolStudent.fromJson(enrollmentMap(item))).toList();
    if (students.map((s) => s.id).toSet().length != students.length ||
        students.map((s) => s.enrollmentId).toSet().length != students.length ||
        students.where((s) => s.followupId != null).map((s) => s.followupId).toSet().length !=
            students.where((s) => s.followupId != null).length) {
      throw const FormatException('Duplicate student enrollment or follow-up');
    }
    return SpecialistSchoolRoster._(expected, school, enrollmentText(data['revision']), students);
  }
}

