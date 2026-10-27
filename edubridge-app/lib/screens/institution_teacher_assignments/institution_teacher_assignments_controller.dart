import '../../model/institutions/institution_teacher_assignments.dart';
import '../../model/schools/teacher_assignment.dart';
import '../../services/institution_teacher_assignments_repository.dart';
import '../enrollment/enrollment_state.dart';

class InstitutionTeacherAssignmentsController
    extends EnrollmentState<InstitutionTeacherAssignments> {
  InstitutionTeacherAssignmentsController(this.gateway) : super(gateway.load);
  final InstitutionTeacherAssignmentsGateway gateway;
  Future<void> remove(InstitutionTeacherAssignment assignment) async {
    final expected = snapshot, writer = gateway;
    if (!canWrite || expected == null || writer is! InstitutionTeacherAssignmentRemover) return;
    await mutate(() => writer.remove(expected, assignment));
  }
  Future<bool> create(TeacherAssignmentDraft draft) async {
    if (!canWrite || snapshot?.canCreate(draft) != true) return false;
    await mutate(() => gateway.create(draft));
    return saved;
  }
}
