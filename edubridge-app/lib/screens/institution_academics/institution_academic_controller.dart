import '../../model/institutions/institution_academic_records.dart';
import '../../model/schools/academic_catalog.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/institution_academic_repository.dart';
import '../academics/academic_form_controller.dart';
import '../enrollment/enrollment_state.dart';

class InstitutionAcademicController
    extends EnrollmentState<InstitutionAcademicRecords>
    implements AcademicFormController {
  InstitutionAcademicController(
    this._gateway, {
    required String organizationSlug,
    required int schoolId,
  }) : super(() async {
         final data = await _gateway.load();
         if (data.organizationSlug != organizationSlug ||
             data.school.id != schoolId) {
           throw const EnrollmentApiException(
             EnrollmentFailure.invalidResponse,
           );
         }
         return data;
       });
  final InstitutionAcademicGateway _gateway;
  bool get supportsCreation => _gateway is InstitutionAcademicWriter;
  @override
  bool get canWrite => super.canWrite && supportsCreation;
  @override
  bool get busy => isAlive && super.busy;
  @override
  Future<bool> create(AcademicDraft draft) async {
    final data = snapshot;
    final gateway = _gateway;
    if (!canWrite ||
        data == null ||
        !draft.valid ||
        gateway is! InstitutionAcademicWriter)
      return false;
    if (draft.kind == AcademicKind.section &&
        (!data.years.any((y) => y.id == draft.yearId) ||
            !data.grades.any((g) => g.id == draft.gradeId)))
      return false;
    await mutate(() => gateway.create(data, draft));
    return saved;
  }
}
