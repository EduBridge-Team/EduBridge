import '../../model/schools/teacher_assignment.dart';
import '../../model/schools/teacher_assignments_catalog.dart';
import '../../services/schools/teacher_assignments_repository.dart';
import '../enrollment/enrollment_state.dart';

class TeacherAssignmentsController
    extends EnrollmentState<TeacherAssignmentsCatalog> {
  TeacherAssignmentsController(this._gateway) : super(_gateway.load);
  final TeacherAssignmentsGateway _gateway;
  Future<bool> create(TeacherAssignmentDraft draft) async {
    final data = snapshot;
    if (!canWrite || data == null || !data.canCreate(draft)) return false;
    await mutate(() => _gateway.create(data.schoolId, draft));
    return saved;
  }

  Future<void> remove(TeacherAssignment assignment) async {
    final data = snapshot;
    if (!canWrite ||
        data == null ||
        !data.assignments.any((v) => v.sameRecord(assignment)))
      return;
    await mutate(() => _gateway.remove(assignment));
  }
}
