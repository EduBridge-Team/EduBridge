import '../../model/institutions/school_specialist_assignments.dart';
import '../../services/school_specialist_assignments_repository.dart';
import '../enrollment/enrollment_state.dart';

class SchoolSpecialistsController extends EnrollmentState<SchoolSpecialistAssignments> {
  SchoolSpecialistsController(this.gateway) : super(gateway.load);
  final SchoolSpecialistAssignmentsGateway gateway;
  Future<void> assign(SchoolSpecialistAssignments expected, int specialistId) async {
    if (!canWrite || !identical(snapshot, expected) || !expected.canAdd(specialistId)) return;
    await mutate(() => gateway.assign(expected, specialistId));
  }
  Future<void> end(SchoolSpecialistAssignments expected, SchoolSpecialistAssignment assignment) async {
    if (!canWrite || !identical(snapshot, expected) || !assignment.active || !assignment.canEnd) return;
    await mutate(() => gateway.end(expected, assignment));
  }
}

