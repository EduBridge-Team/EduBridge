import 'dart:convert';

import 'iep_draft.dart';
import 'iep_draft_save.dart';
import 'iep_plan_history.dart';
import 'iep_version.dart';

/// Immutable authoring baseline. This is not server authorization or a lock.
class IepEditSource {
  IepEditSource._(this.planId, this.versionId, this.draft, this._fingerprint);
  final int planId, versionId;
  final IepPlanDraft draft;
  final String _fingerprint;

  factory IepEditSource.capture(IepPlan plan, IepVersion version) {
    if (plan.closed || version.status != IepVersionStatus.draft ||
        version.planId != plan.id || version.childId != plan.childId ||
        !plan.versions.any((item) => identical(item, version))) {
      throw const FormatException('IEP version is not an editable draft');
    }
    final draft = IepPlanDraft(
      childId: plan.childId, evaluationId: version.evaluationId,
      title: plan.title, summary: version.summary ?? '',
      start: version.start, end: version.end, reviewOn: version.reviewOn,
      accommodations: version.accommodations,
      goals: [for (final goal in version.goals) IepDraftGoal(
        title: goal.title, baseline: goal.baseline, target: goal.target,
        unit: goal.unit, method: goal.method, responsible: goal.responsible ?? '',
        start: goal.start, end: goal.end,
      )],
    );
    return IepEditSource._(plan.id, version.id, draft,
      _snapshot(plan, version, draft));
  }

  bool matches(IepPlan plan, IepVersion version) {
    try {
      final current = IepEditSource.capture(plan, version);
      return planId == current.planId && versionId == current.versionId &&
        _fingerprint == current._fingerprint;
    } on FormatException {
      return false;
    }
  }

  static String _snapshot(IepPlan plan, IepVersion version, IepPlanDraft draft) =>
    jsonEncode({
      'child': plan.childId, 'approved': plan.currentApprovedId,
      'versions': [for (final item in plan.versions) [item.id, item.number, item.status.name]],
      'version': version.number, 'author': version.author,
      'created': version.createdAt.toIso8601String(),
      'goals': [for (final goal in version.goals) goal.id],
      'comments': [for (final comment in version.comments)
        [comment.id, comment.text, comment.author, comment.createdAt.toIso8601String()]],
      'payload': iepDraftPayload(draft),
    });
}
