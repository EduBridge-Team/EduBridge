import 'dart:math';

import '../enrollment/enrollment_models.dart';
import 'iep_draft.dart';
import 'iep_plan_history.dart';
import 'iep_version.dart';

String newIepDraftRequestKey() {
  final random = Random.secure();
  return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

String iepDraftDay(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

Map<String, dynamic> iepDraftPayload(IepPlanDraft draft) => {
  'evaluation_id': draft.evaluationId,
  'title': draft.title,
  'summary': draft.summary,
  'starts_on': iepDraftDay(draft.start),
  'ends_on': iepDraftDay(draft.end),
  'review_on': iepDraftDay(draft.reviewOn),
  'goals': [for (final goal in draft.goals) {
    'title': goal.title, 'baseline': goal.baseline, 'target': goal.target,
    'unit': goal.unit, 'measurement_method': goal.method,
    'responsible_name': goal.responsible.isEmpty ? null : goal.responsible,
    'starts_on': iepDraftDay(goal.start), 'ends_on': iepDraftDay(goal.end),
  }],
  'accommodations': draft.accommodations.toList(),
};

class IepDraftSaveOptions {
  IepDraftSaveOptions._(this.childId, this.canCreate, this.evaluationIds);
  final int childId;
  final bool canCreate;
  final Set<int> evaluationIds;
  factory IepDraftSaveOptions.fromJson(int childId, Map<String, dynamic> data) {
    final ids = enrollmentList(data['evaluation_ids']).map(enrollmentId).toList();
    if (enrollmentId(data['child_id']) != childId ||
        data['can_create_draft'] is! bool || ids.toSet().length != ids.length) {
      throw const FormatException('Invalid draft options');
    }
    return IepDraftSaveOptions._(childId, data['can_create_draft'] as bool, Set.unmodifiable(ids));
  }
}

/// A server-owned new plan with exactly one unapproved draft version.
class IepSavedDraft {
  IepSavedDraft(this.plan);
  final IepPlan plan;
  IepVersion get version => plan.versions.single;

  bool matches(IepPlanDraft draft) {
    if (plan.childId != draft.childId || plan.closed || plan.currentApprovedId != null ||
        plan.title != draft.title || plan.versions.length != 1) { return false; }
    final v = version;
    if (v.status != IepVersionStatus.draft || v.number != 1 ||
        v.evaluationId != draft.evaluationId || (v.summary ?? '') != draft.summary ||
        v.returnReason != null || v.comments.isNotEmpty ||
        iepDraftDay(v.start) != iepDraftDay(draft.start) ||
        iepDraftDay(v.end) != iepDraftDay(draft.end) ||
        iepDraftDay(v.reviewOn) != iepDraftDay(draft.reviewOn) ||
        v.goals.length != draft.goals.length ||
        v.accommodations.length != draft.accommodations.length) { return false; }
    for (var i = 0; i < v.accommodations.length; i++) {
      if (v.accommodations[i] != draft.accommodations[i]) return false;
    }
    for (var i = 0; i < v.goals.length; i++) {
      final goal = v.goals[i], expected = draft.goals[i];
      if (goal.title != expected.title || goal.baseline != expected.baseline ||
          goal.target != expected.target || goal.unit != expected.unit ||
          goal.method != expected.method || (goal.responsible ?? '') != expected.responsible ||
          iepDraftDay(goal.start) != iepDraftDay(expected.start) ||
          iepDraftDay(goal.end) != iepDraftDay(expected.end)) { return false; }
    }
    return true;
  }
}
