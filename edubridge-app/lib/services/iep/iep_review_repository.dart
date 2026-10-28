import 'dart:convert';
import '../../model/iep/iep_plan_history.dart';
import '../../model/iep/iep_review.dart';
import '../../model/iep/iep_version.dart';
import '../enrollment/enrollment_api_client.dart';

abstract interface class IepReviewGateway {
  Future<IepReviewOptions> load();
  Future<void> act(IepReviewAction action, IepReviewOptions expected, String key, {String reason = ''});
}

/// Proposed frontend contract; unsupported options cannot enable a mutation.
class IepReviewRepository implements IepReviewGateway {
  IepReviewRepository({required this.source, EnrollmentApiClient? client})
    : _client = client ?? EnrollmentApiClient();
  final IepReviewSource source;
  final EnrollmentApiClient _client;
  String get _history => '/children/${source.plan.childId}/iep-plans';
  String get _root => '$_history/${source.plan.id}/versions/${source.version.id}';
  Future<IepPlan> _read() async {
    final history = IepPlanHistory.fromJson(source.plan.childId, await _client.get(_history));
    return history.plans.singleWhere((p) => p.id == source.plan.id);
  }
  @override
  Future<IepReviewOptions> load() async {
    try {
      final data = await _client.get('$_root/review-options');
      if (data['contract_version'] != 1 || data['child_id'] != source.plan.childId ||
          data['plan_id'] != source.plan.id || data['version_id'] != source.version.id ||
          data['revision'] is! String || (data['revision'] as String).trim().isEmpty ||
          data['allowed_actions'] is! List) throw const FormatException('Invalid review options');
      final names = (data['allowed_actions'] as List).cast<String>();
      final actions = <IepReviewAction>{};
      for (final name in names) {
        actions.add(IepReviewAction.values.singleWhere((a) => iepReviewActionName(a) == name));
      }
      if (actions.length != names.length) throw const FormatException('Duplicate review action');
      if (source.plan.closed || actions.any((a) => !iepReviewActionFits(source.version.status, a))) {
        throw const EnrollmentApiException(EnrollmentFailure.conflict);
      }
      if (!source.matches(await _read())) throw const EnrollmentApiException(EnrollmentFailure.conflict);
      return IepReviewOptions(data['revision'] as String, actions);
    } on EnrollmentApiException { rethrow; }
    on Object { throw const EnrollmentApiException(EnrollmentFailure.invalidResponse); }
  }
  @override
  Future<void> act(IepReviewAction action, IepReviewOptions expected, String key, {String reason = ''}) async {
    reason = reason.trim();
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(key) ||
        (action == IepReviewAction.returnForChanges && (reason.isEmpty || reason.length > 2000)) ||
        (action != IepReviewAction.returnForChanges && reason.isNotEmpty)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await load();
    if (current.revision != expected.revision) throw const EnrollmentApiException(EnrollmentFailure.conflict);
    if (!current.actions.contains(action) || !expected.actions.contains(action)) {
      throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    }
    try {
      final receipt = await _client.post('$_root/review', {
        'action': iepReviewActionName(action), 'expected_revision': expected.revision,
        'request_key': key, if (action == IepReviewAction.returnForChanges) 'reason': reason,
      }, success: 200);
      if (receipt['child_id'] != source.plan.childId || receipt['plan_id'] != source.plan.id ||
          receipt['version_id'] != source.version.id || receipt['request_key'] != key ||
          receipt['action'] != iepReviewActionName(action) || receipt['revision'] is! String ||
          (receipt['revision'] as String).trim().isEmpty || receipt['revision'] == expected.revision) {
        throw const FormatException('Invalid review receipt');
      }
      final plan = IepPlan.fromJson(Map<String, dynamic>.from(receipt['plan'] as Map));
      final version = plan.versions.singleWhere((v) => v.id == source.version.id);
      final status = switch (action) {
        IepReviewAction.submit => IepVersionStatus.submitted,
        IepReviewAction.returnForChanges => IepVersionStatus.returned,
        IepReviewAction.approve => IepVersionStatus.approved,
      };
      if (plan.id != source.plan.id || plan.childId != source.plan.childId || plan.closed ||
          plan.title != source.plan.title || version.status != status ||
          jsonEncode(iepReviewContent(version)) != jsonEncode(iepReviewContent(source.version)) ||
          source.version.comments.any((before) => !version.comments.any((after) =>
            before.id == after.id && before.text == after.text && before.author == after.author &&
            before.createdAt == after.createdAt)) ||
          iepReviewOtherVersions(plan, version.id) != iepReviewOtherVersions(source.plan, version.id) ||
          plan.currentApprovedId != (action == IepReviewAction.approve ? version.id : source.plan.currentApprovedId) ||
          (action == IepReviewAction.returnForChanges && version.returnReason != reason) ||
          (action != IepReviewAction.returnForChanges && version.returnReason != null)) {
        throw const FormatException('Mismatched review result');
      }
      if (!IepReviewSource(plan, version).matches(await _read())) {
        throw const FormatException('Unconfirmed review');
      }
    } on EnrollmentApiException catch (error) {
      if ([EnrollmentFailure.conflict, EnrollmentFailure.validation, EnrollmentFailure.forbidden,
        EnrollmentFailure.session, EnrollmentFailure.unavailable, EnrollmentFailure.rateLimited].contains(error.failure)) rethrow;
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    } on Object { throw const EnrollmentApiException(EnrollmentFailure.uncertain); }
  }
}
