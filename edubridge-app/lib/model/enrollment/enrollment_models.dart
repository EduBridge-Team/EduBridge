/// Enrollment contracts keep the existing child identity throughout the flow.
int enrollmentId(dynamic value) {
  if (value is! int || value <= 0) throw const FormatException('Invalid ID');
  return value;
}

String enrollmentText(dynamic value) {
  if (value is! String || value.trim().isEmpty)
    throw const FormatException('Missing text');
  return value;
}

Map<String, dynamic> enrollmentMap(dynamic value) {
  if (value is! Map<String, dynamic>)
    throw const FormatException('Expected object');
  return value;
}

List<dynamic> enrollmentList(dynamic value) {
  if (value is! List) throw const FormatException('Expected list');
  return value;
}

enum EnrollmentStatus { pending, approved, rejected, cancelled }

class EnrollmentSchool {
  const EnrollmentSchool({
    required this.id,
    required this.name,
    this.address = '',
  });
  final int id;
  final String name;
  final String address;
  factory EnrollmentSchool.fromJson(Map<String, dynamic> data) {
    if (data['address'] != null && data['address'] is! String)
      throw const FormatException('Invalid address');
    return EnrollmentSchool(
      id: enrollmentId(data['id']),
      name: enrollmentText(data['name']),
      address: data['address'] as String? ?? '',
    );
  }
}

class SchoolPortalIdentity {
  const SchoolPortalIdentity({
    required this.school,
    required this.organizationId,
  });
  final EnrollmentSchool school;
  final int? organizationId;
  factory SchoolPortalIdentity.fromJson(Map<String, dynamic> data) {
    if (!data.containsKey('organization_id'))
      throw const FormatException('Missing ownership');
    return SchoolPortalIdentity(
      school: EnrollmentSchool.fromJson(data),
      organizationId: data['organization_id'] == null
          ? null
          : enrollmentId(data['organization_id']),
    );
  }
}

class EnrollmentSection {
  const EnrollmentSection({
    required this.id,
    required this.name,
    required this.gradeName,
    required this.academicYearId,
    required this.academicYearName,
  });
  final int id;
  final String name;
  final String gradeName;
  final int academicYearId;
  final String academicYearName;
  String get label => '$academicYearName / $gradeName / $name';
  factory EnrollmentSection.fromJson(Map<String, dynamic> data) =>
      EnrollmentSection(
        id: enrollmentId(data['id']),
        name: enrollmentText(data['name']),
        gradeName: enrollmentText(data['grade_name']),
        academicYearId: enrollmentId(data['academic_year_id']),
        academicYearName: enrollmentText(data['academic_year_name']),
      );
}

class EnrollmentRequest {
  const EnrollmentRequest({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.childId,
    required this.childName,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.reason,
  });
  final int id;
  final int schoolId;
  final String schoolName;
  final int childId;
  final String childName;
  final EnrollmentStatus status;
  final int version;
  final DateTime createdAt;
  final String? reason;
  factory EnrollmentRequest.fromJson(Map<String, dynamic> data) {
    final status = EnrollmentStatus.values.where(
      (s) => s.name == data['status'],
    );
    final created = data['created_at'] is String
        ? DateTime.tryParse(data['created_at'] as String)
        : null;
    if (status.length != 1 ||
        created == null ||
        (data['reason'] != null && data['reason'] is! String)) {
      throw const FormatException('Invalid request state');
    }
    if (status.single == EnrollmentStatus.rejected &&
        (data['reason'] == null || (data['reason'] as String).trim().isEmpty)) {
      throw const FormatException('Rejection requires reason');
    }
    return EnrollmentRequest(
      id: enrollmentId(data['id']),
      schoolId: enrollmentId(data['school_id']),
      schoolName: enrollmentText(data['school_name']),
      childId: enrollmentId(data['child_id']),
      childName: enrollmentText(data['child_name']),
      status: status.single,
      version: enrollmentId(data['version']),
      createdAt: created,
      reason: data['reason'] as String?,
    );
  }
}

class ActiveSchoolEnrollment {
  const ActiveSchoolEnrollment({
    required this.id,
    required this.childId,
    required this.schoolId,
    required this.schoolName,
    required this.sectionId,
  });
  final int id;
  final int childId;
  final int schoolId;
  final String schoolName;
  final int sectionId;
  factory ActiveSchoolEnrollment.fromJson(Map<String, dynamic> data) {
    if (data['status'] != 'active')
      throw const FormatException('Expected active enrollment');
    return ActiveSchoolEnrollment(
      id: enrollmentId(data['id']),
      childId: enrollmentId(data['child_id']),
      schoolId: enrollmentId(data['school_id']),
      schoolName: enrollmentText(data['school_name']),
      sectionId: enrollmentId(data['section_id']),
    );
  }
}

class SchoolEnrollmentInbox {
  SchoolEnrollmentInbox({
    required this.identity,
    required List<EnrollmentRequest> requests,
    required List<EnrollmentSection> sections,
  }) : requests = List.unmodifiable(requests),
       sections = List.unmodifiable(sections);
  final SchoolPortalIdentity identity;
  final List<EnrollmentRequest> requests;
  final List<EnrollmentSection> sections;
}

class ParentEnrollmentHistory {
  ParentEnrollmentHistory({
    required List<EnrollmentRequest> requests,
    required this.activeEnrollment,
  }) : requests = List.unmodifiable(requests);
  final List<EnrollmentRequest> requests;
  final ActiveSchoolEnrollment? activeEnrollment;
  bool get canRequest =>
      activeEnrollment == null &&
      !requests.any((r) => r.status == EnrollmentStatus.pending);
}

class EnrollmentDecision {
  const EnrollmentDecision({
    required this.approve,
    this.sectionId,
    this.reason = '',
  });
  final bool approve;
  final int? sectionId;
  final String reason;
}
