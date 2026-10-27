import '../../model/iep/iep_draft.dart';
import '../../model/iep/iep_draft_save.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/iep/iep_draft_repository.dart';
import '../enrollment/enrollment_state.dart';

class IepDraftSaveController extends EnrollmentState<IepDraftSaveOptions> {
  IepDraftSaveController(this.draft, this.gateway, {String? requestKey})
    : requestKey = requestKey ?? newIepDraftRequestKey(), super(() async {
    final options = await gateway.options();
    if (options.childId != draft.childId) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
    return options;
  });
  final IepPlanDraft draft;
  final IepDraftGateway gateway;
  final String requestKey;
  IepSavedDraft? receipt;
  bool needsReview = false;
  bool get canCreate => canWrite && receipt == null && !needsReview &&
      snapshot!.canCreate && snapshot!.evaluationIds.contains(draft.evaluationId);

  Future<void> create(IepDraftSaveOptions expected) async {
    if (!canCreate || !identical(snapshot, expected)) return;
    await mutate(() async {
      try {
        final saved = await gateway.create(draft, requestKey);
        if (!saved.matches(draft)) {
          throw const EnrollmentApiException(EnrollmentFailure.uncertain);
        }
        if (isAlive) receipt = saved;
      } on EnrollmentApiException catch (error) {
        if (isAlive && error.failure == EnrollmentFailure.uncertain) needsReview = true;
        rethrow;
      }
    });
  }
}
