import 'dart:convert';

import '../../model/iep/iep_draft.dart';
import '../../model/iep/iep_draft_save.dart';
import '../../model/iep/iep_edit_source.dart';
import '../../model/iep/iep_plan_history.dart';
import '../enrollment/enrollment_api_client.dart';

class IepDraftEditOptions {
  const IepDraftEditOptions(this.revision, this.evaluationIds);
  final String revision;
  final Set<int> evaluationIds;
}

abstract interface class IepDraftUpdateGateway {
  Future<IepDraftEditOptions> load();
  Future<void> update(IepPlanDraft draft, IepDraftEditOptions expected, String requestKey);
}

/// Proposed, capability-gated client contract. Missing options never allow PATCH.
class IepDraftUpdateRepository implements IepDraftUpdateGateway {
  IepDraftUpdateRepository({required this.source, EnrollmentApiClient? client})
    : _client = client ?? EnrollmentApiClient();
  final IepEditSource source;
  final EnrollmentApiClient _client;
  String get _history => '/children/${source.draft.childId}/iep-plans';
  String get _root => '$_history/${source.planId}/versions/${source.versionId}';

  Future<IepPlan> _read() async {
    final data = IepPlanHistory.fromJson(source.draft.childId, await _client.get(_history));
    return data.plans.singleWhere((plan) => plan.id == source.planId);
  }

  @override
  Future<IepDraftEditOptions> load() async {
    try {
      final data = await _client.get('$_root/edit-options');
      if (data['contract_version'] != 1 || data['child_id'] != source.draft.childId ||
          data['plan_id'] != source.planId || data['version_id'] != source.versionId ||
          data['can_edit'] is! bool || data['revision'] is! String ||
          (data['revision'] as String).trim().isEmpty || data['evaluation_ids'] is! List) {
        throw const FormatException('Invalid edit options');
      }
      if (data['can_edit'] != true) {
        throw const EnrollmentApiException(EnrollmentFailure.forbidden);
      }
      final ids = (data['evaluation_ids'] as List).cast<int>();
      if (ids.any((id) => id < 1) || ids.toSet().length != ids.length) {
        throw const FormatException('Invalid evaluation eligibility');
      }
      final plan = await _read();
      final versions = plan.versions.where((v) => v.id == source.versionId).toList();
      if (versions.length != 1 || !source.matches(plan, versions.single)) {
        throw const EnrollmentApiException(EnrollmentFailure.conflict);
      }
      return IepDraftEditOptions(data['revision'] as String, Set.unmodifiable(ids));
    } on EnrollmentApiException {
      rethrow;
    } on Object {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  @override
  Future<void> update(IepPlanDraft draft, IepDraftEditOptions expected, String requestKey) async {
    if (draft.childId != source.draft.childId || !RegExp(r'^[a-f0-9]{32}$').hasMatch(requestKey)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await load();
    if (current.revision != expected.revision) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    if (!current.evaluationIds.contains(draft.evaluationId)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    try {
      final receipt = await _client.patch(_root, {...iepDraftPayload(draft),
        'expected_revision': expected.revision, 'request_key': requestKey});
      if (receipt['request_key'] != requestKey || receipt['child_id'] != draft.childId ||
          receipt['plan_id'] != source.planId || receipt['version_id'] != source.versionId ||
          receipt['revision'] is! String || (receipt['revision'] as String).trim().isEmpty ||
          receipt['revision'] == expected.revision) {
        throw const FormatException('Invalid update receipt');
      }
      final plan = IepPlan.fromJson(Map<String, dynamic>.from(receipt['plan'] as Map));
      final version = plan.versions.singleWhere((v) => v.id == source.versionId);
      final result = IepEditSource.capture(plan, version);
      if (result.planId != source.planId || result.versionId != source.versionId ||
          jsonEncode(iepDraftPayload(result.draft)) != jsonEncode(iepDraftPayload(draft))) {
        throw const FormatException('Mismatched saved content');
      }
      final confirmed = await _read();
      final confirmedVersion = confirmed.versions.singleWhere((v) => v.id == source.versionId);
      if (!result.matches(confirmed, confirmedVersion)) {
        throw const FormatException('Unconfirmed update');
      }
    } on EnrollmentApiException catch (error) {
      if ([EnrollmentFailure.conflict, EnrollmentFailure.validation, EnrollmentFailure.forbidden,
        EnrollmentFailure.session, EnrollmentFailure.unavailable, EnrollmentFailure.rateLimited].contains(error.failure)) rethrow;
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    } on Object {
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    }
  }
}
