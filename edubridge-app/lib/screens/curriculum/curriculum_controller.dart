import '../../model/schools/curriculum_catalog.dart';
import '../../model/schools/curriculum_draft.dart';
import '../../services/schools/curriculum_repository.dart';
import '../enrollment/enrollment_state.dart';

class CurriculumController extends EnrollmentState<CurriculumCatalog> {
  CurriculumController(this._gateway) : super(_gateway.load);
  final CurriculumGateway _gateway;
  Future<bool> create(CurriculumDraft draft) async {
    final data = snapshot;
    if (!canWrite || data == null || !draft.validFor(data)) return false;
    await mutate(() => _gateway.create(data.school.id, draft));
    return saved;
  }
}
