import '../../model/enrollment/enrollment_models.dart';
import '../../model/iep/iep_draft.dart';
import '../../model/iep/iep_draft_save.dart';
import '../../model/iep/iep_plan_history.dart';
import '../../model/iep/iep_snapshot.dart';
import '../../model/iep/iep_version.dart';
import '../enrollment/enrollment_api_client.dart';
import 'iep_history_repository.dart';

class IepCompletionOptions {
  IepCompletionOptions(this.childId, this.revision, this.canComplete, Set<int> evaluations)
      : evaluationIds = Set.unmodifiable(evaluations);
  final int childId;
  final String revision;
  final bool canComplete;
  final Set<int> evaluationIds;

  factory IepCompletionOptions.fromJson(int expected, Map<String, dynamic> data) {
    final ids = enrollmentList(data['evaluation_ids']).map(enrollmentId).toList();
    final revision = data['revision'];
    if (data['contract_version'] != 1 || enrollmentId(data['child_id']) != expected ||
        revision is! String || revision.trim().isEmpty ||
        data['can_complete'] is! bool || ids.toSet().length != ids.length) {
      throw const FormatException('Invalid completion options');
    }
    return IepCompletionOptions(expected, revision, data['can_complete'] as bool, ids.toSet());
  }
}

abstract interface class IepCompletionGateway {
  Future<IepCompletionOptions> options();
  /// Atomically create and complete a new educational plan, not a ministry review.
  Future<void> complete(IepPlanDraft draft, IepCompletionOptions expected, String key);
}

/// Proposed API: missing completion options never grant publication.
/// Both writes and their receipts must be scoped to the logged-in specialist and child.
class IepCompletionRepository implements IepCompletionGateway {
  IepCompletionRepository({required this.childId, EnrollmentApiClient? client})
      : _client = client ?? EnrollmentApiClient();

  final int childId;
  final EnrollmentApiClient _client;

  @override
  Future<IepCompletionOptions> options() async {
    if (childId < 1) throw const EnrollmentApiException(EnrollmentFailure.validation);
    final data = await _client.get('/children/$childId/iep-completion-options');
    try {
      return IepCompletionOptions.fromJson(childId, data);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  bool _matches(IepPlan plan, IepPlanDraft draft) {
    if (plan.childId != draft.childId || plan.closed ||
        plan.currentApprovedId != null || plan.title != draft.title ||
        plan.versions.length != 1) return false;
    final v = plan.versions.single;
    if (v.status != IepVersionStatus.completed || v.number != 1 ||
        v.evaluationId != draft.evaluationId ||
        (v.summary ?? '') != draft.summary || v.returnReason != null ||
        iepDraftDay(v.start) != iepDraftDay(draft.start) ||
        iepDraftDay(v.end) != iepDraftDay(draft.end) ||
        iepDraftDay(v.reviewOn) != iepDraftDay(draft.reviewOn) ||
        v.goals.length != draft.goals.length ||
        v.accommodations.length != draft.accommodations.length) return false;
    for (var i = 0; i < draft.accommodations.length; i++) {
      if (v.accommodations[i] != draft.accommodations[i]) return false;
    }
    for (var i = 0; i < draft.goals.length; i++) {
      final goal = v.goals[i], expected = draft.goals[i];
      if (goal.title != expected.title || goal.baseline != expected.baseline ||
          goal.target != expected.target || goal.unit != expected.unit ||
          goal.method != expected.method ||
          (goal.responsible ?? '') != expected.responsible ||
          iepDraftDay(goal.start) != iepDraftDay(expected.start) ||
          iepDraftDay(goal.end) != iepDraftDay(expected.end)) return false;
    }
    return true;
  }

  @override
  Future<void> complete(IepPlanDraft draft, IepCompletionOptions expected, String key) async {
    if (draft.childId != childId || expected.childId != childId ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(key)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await options();
    if (current.revision != expected.revision ||
        current.canComplete != expected.canComplete ||
        !current.evaluationIds.contains(draft.evaluationId)) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    if (!current.canComplete) throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    final history = IepHistoryRepository(childId: childId, client: _client);
    final before = await history.load();
    var mayHaveWritten = false;
    try {
      mayHaveWritten = true;
      final data = await _client.post('/children/$childId/iep-plans/complete', {
        ...iepDraftPayload(draft),
        'request_key': key,
        'expected_revision': current.revision,
      });
      if (enrollmentId(data['child_id']) != childId || data['request_key'] != key ||
          data['status'] != 'completed') {
        throw const FormatException('Foreign completion receipt');
      }
      final plan = IepPlan.fromJson(enrollmentMap(data['plan']));
      if (!_matches(plan, draft) || before.plans.any((p) => p.id == plan.id) ||
          before.plans.expand((p) => p.versions).any((v) => v.id == plan.versions.single.id)) {
        throw const FormatException('Completion receipt does not match authored plan');
      }
      final after = await history.load();
      final others = {for (final item in after.plans.where((p) => p.id != plan.id))
        item.id: iepSnapshotFingerprint(iepPlanSnapshot(item))};
      if (others.length != before.plans.length || before.plans.any((item) =>
          others[item.id] != iepSnapshotFingerprint(iepPlanSnapshot(item)))) {
        throw const FormatException('Existing plan history changed');
      }
      final matches = after.plans.where((item) => item.id == plan.id).toList();
      if (matches.length != 1 || !_matches(matches.single, draft) ||
          iepSnapshotFingerprint(iepPlanSnapshot(matches.single)) !=
              iepSnapshotFingerprint(iepPlanSnapshot(plan))) {
        throw const FormatException('Completed plan not confirmed in specialist history');
      }
    } on EnrollmentApiException catch (e) {
      if (mayHaveWritten && !const {EnrollmentFailure.forbidden,
          EnrollmentFailure.validation, EnrollmentFailure.conflict,
          EnrollmentFailure.session, EnrollmentFailure.unavailable,
          EnrollmentFailure.rateLimited}.contains(e.failure)) {
        throw const EnrollmentApiException(EnrollmentFailure.uncertain);
      }
      rethrow;
    } on Object {
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    }
  }
}
