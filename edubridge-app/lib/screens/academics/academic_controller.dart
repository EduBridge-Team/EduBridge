import '../../model/schools/academic_catalog.dart';
import '../../services/schools/academic_repository.dart';
import '../enrollment/enrollment_state.dart';
import 'academic_form_controller.dart';

class AcademicController extends EnrollmentState<AcademicCatalog>
    implements AcademicFormController {
  AcademicController(this._gateway) : super(_gateway.load);
  final AcademicGateway _gateway;

  Future<bool> create(AcademicDraft draft) async {
    final data = snapshot;
    if (!canWrite || data == null || !draft.valid) return false;
    if (draft.kind == AcademicKind.section &&
        (!data.years.any((v) => v.id == draft.yearId) ||
            !data.grades.any((v) => v.id == draft.gradeId))) {
      return false;
    }
    await mutate(() => _gateway.create(data.school.id, draft));
    return saved;
  }
}
