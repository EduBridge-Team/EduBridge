import '../../model/schools/specialist_school_students.dart';
import '../../services/specialist_school_students_repository.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../enrollment/enrollment_state.dart';

class SpecialistSchoolStudentsController extends EnrollmentState<SpecialistSchoolRoster> {
  SpecialistSchoolStudentsController(this.gateway, this.specialistId, this.school)
      : super(() async {
          final roster = await gateway.students(specialistId, school);
          if (roster.specialistId != specialistId || !roster.school.sameScope(school)) {
            throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
          }
          return roster;
        });
  final SpecialistSchoolStudentsGateway gateway;
  final int specialistId;
  final SpecialistSchool school;
  Future<void> follow(SpecialistSchoolRoster expected, SpecialistSchoolStudent student) async {
    if (!canWrite || !identical(snapshot, expected) || expected.specialistId != specialistId ||
        !expected.school.sameScope(school) || !student.canFollow || student.following) return;
    await mutate(() => gateway.follow(expected, student));
  }
}

