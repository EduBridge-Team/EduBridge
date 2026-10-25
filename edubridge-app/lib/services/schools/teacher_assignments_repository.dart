import '../../model/enrollment/enrollment_models.dart';
import '../../model/schools/teacher_assignment.dart';
import '../../model/schools/teacher_assignments_catalog.dart';
import '../enrollment/enrollment_api_client.dart';

abstract interface class TeacherAssignmentsGateway {
  Future<TeacherAssignmentsCatalog> load();
  Future<void> create(int schoolId, TeacherAssignmentDraft draft);
  Future<void> remove(TeacherAssignment assignment);
}

class TeacherAssignmentsRepository implements TeacherAssignmentsGateway {
  TeacherAssignmentsRepository({EnrollmentApiClient? client})
    : _client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient _client;
  @override
  Future<TeacherAssignmentsCatalog> load() async {
    final context = await _client.get('/school/context');
    final data = await _client.get('/school/teacher-assignments');
    try {
      final identity = SchoolPortalIdentity.fromJson(
        enrollmentMap(context['school']),
      );
      final catalog = TeacherAssignmentsCatalog.fromJson(data);
      if (catalog.schoolId != identity.school.id)
        throw const FormatException('Foreign school');
      return catalog;
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  @override
  Future<void> create(int schoolId, TeacherAssignmentDraft draft) async {
    if (schoolId < 1 || !draft.valid) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final data = await _client.post('/school/teacher-assignments', {
      ...draft.toJson(),
      'expected_school_id': schoolId,
    });
    try {
      final item = TeacherAssignment.fromJson(
        enrollmentMap(data['assignment']),
      );
      if (enrollmentId(data['school_id']) != schoolId ||
          item.schoolId != schoolId ||
          item.identity != draft.identity ||
          item.version != 1) {
        throw const FormatException('Mismatched assignment receipt');
      }
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  @override
  Future<void> remove(TeacherAssignment assignment) async {
    if (assignment.id < 1 ||
        assignment.schoolId < 1 ||
        assignment.version < 1 ||
        !TeacherAssignmentDraft(
          teacherId: assignment.teacherId,
          sectionId: assignment.sectionId,
          subjectId: assignment.subjectId,
        ).valid) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final data = await _client.post(
      '/school/teacher-assignments/${assignment.id}/remove',
      {
        'expected_school_id': assignment.schoolId,
        'expected_version': assignment.version,
      },
      success: 200,
    );
    try {
      final item = TeacherAssignment.fromJson(
        enrollmentMap(data['assignment']),
      );
      if (data['removed'] != true ||
          enrollmentId(data['school_id']) != assignment.schoolId ||
          item.id != assignment.id ||
          item.schoolId != assignment.schoolId ||
          item.identity != assignment.identity ||
          item.version != assignment.version + 1) {
        throw const FormatException('Mismatched removal receipt');
      }
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
