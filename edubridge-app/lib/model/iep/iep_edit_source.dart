
import 'iep_draft.dart';
import 'iep_draft_save.dart';
import 'iep_plan_history.dart';
import 'iep_snapshot.dart';
import 'iep_version.dart';

/// Immutable authoring baseline. This is not server authorization or a lock.
class IepEditSource {
  IepEditSource._(this.planId, this.versionId, this.draft, this._fingerprint,
      this._preservedFingerprint);
  final int planId, versionId;
  final IepPlanDraft draft;
  final String _fingerprint;
  final String _preservedFingerprint;

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
      _snapshot(plan, version, draft), _preservedSnapshot(plan, version));
  }

  /// Editing authoring fields must not rewrite prior versions or audit identity.
  bool preservesHistory(IepPlan plan, IepVersion version) {
    try {
      final result = IepEditSource.capture(plan, version);
      return planId == result.planId && versionId == result.versionId &&
          _preservedFingerprint == result._preservedFingerprint;
    } on FormatException {
      return false;
    }
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
    iepSnapshotFingerprint({
      'child': plan.childId, 'approved': plan.currentApprovedId,
      'versions': [for (final item in plan.versions) [item.id, item.number, item.status.name]],
      'other_versions': [for (final item in plan.versions.where((v) => v.id != version.id))
        iepVersionSnapshot(item)],
      'version': version.number, 'author': version.author,
      'created': version.createdAt.toIso8601String(),
      'goals': [for (final goal in version.goals) goal.id],
      'comments': [for (final comment in version.comments)
        [comment.id, comment.text, comment.author, comment.createdAt.toIso8601String()]],
      'payload': iepDraftPayload(draft),
    });

  static String _preservedSnapshot(IepPlan plan, IepVersion version) =>
    iepSnapshotFingerprint({
      'child': plan.childId, 'approved': plan.currentApprovedId,
      'version': version.number, 'author': version.author,
      'created': version.createdAt.toIso8601String(),
      'comments': [for (final c in version.comments)
        [c.id, c.text, c.author, c.createdAt.toIso8601String()]],
      'other_versions': [for (final item in plan.versions.where((v) => v.id != version.id))
        iepVersionSnapshot(item)],
    });
}
