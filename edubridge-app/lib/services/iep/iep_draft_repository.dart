import '../../model/enrollment/enrollment_models.dart';
import '../../model/iep/iep_draft.dart';
import '../../model/iep/iep_draft_save.dart';
import '../../model/iep/iep_plan_history.dart';
import '../enrollment/enrollment_api_client.dart';
import 'iep_history_repository.dart';

abstract interface class IepDraftGateway {
  Future<IepDraftSaveOptions> options();
  Future<IepSavedDraft> create(IepPlanDraft draft, String requestKey);
}

/// Proposed write contract; an unavailable options route never enables POST.
class IepDraftRepository implements IepDraftGateway {
  IepDraftRepository({required this.childId, EnrollmentApiClient? client})
    : _client = client ?? EnrollmentApiClient();
  final int childId;
  final EnrollmentApiClient _client;
  String get _root => '/children/$childId/iep-plans';

  @override
  Future<IepDraftSaveOptions> options() async {
    if (childId < 1) throw const EnrollmentApiException(EnrollmentFailure.validation);
    final data = await _client.get('/children/$childId/iep-draft-options');
    try {
      return IepDraftSaveOptions.fromJson(childId, data);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  @override
  Future<IepSavedDraft> create(IepPlanDraft draft, String requestKey) async {
    if (draft.childId != childId || !RegExp(r'^[a-f0-9]{32}$').hasMatch(requestKey)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final available = await options();
    if (!available.canCreate) throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    if (!available.evaluationIds.contains(draft.evaluationId)) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    final history = IepHistoryRepository(childId: childId, client: _client);
    final before = await history.load();
    var confirmed = false;
    try {
      final data = await _client.post(_root, {
        ...iepDraftPayload(draft), 'request_key': requestKey,
      });
      confirmed = true;
      if (enrollmentId(data['child_id']) != childId || data['request_key'] != requestKey) {
        throw const FormatException('Foreign draft receipt');
      }
      final receipt = IepSavedDraft(IepPlan.fromJson(enrollmentMap(data['plan'])));
      if (!receipt.matches(draft) || before.plans.any((p) => p.id == receipt.plan.id) ||
          before.plans.expand((p) => p.versions).any((v) => v.id == receipt.version.id)) {
        throw const FormatException('Draft identity or content mismatch');
      }
      final after = await history.load();
      final matches = after.plans.where((p) => p.id == receipt.plan.id).toList();
      if (matches.length != 1) throw const FormatException('Missing saved draft');
      final saved = IepSavedDraft(matches.single);
      if (!saved.matches(draft) || saved.version.id != receipt.version.id) {
        throw const FormatException('Unconfirmed saved draft');
      }
      return saved;
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    } on EnrollmentApiException catch (error) {
      if (confirmed || const {
        EnrollmentFailure.uncertain, EnrollmentFailure.server,
        EnrollmentFailure.invalidResponse, EnrollmentFailure.network,
      }.contains(error.failure)) {
        throw const EnrollmentApiException(EnrollmentFailure.uncertain);
      }
      rethrow;
    }
  }
}
