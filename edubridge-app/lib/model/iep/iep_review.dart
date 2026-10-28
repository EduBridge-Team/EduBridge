import 'dart:convert';
import 'iep_plan_history.dart';
import 'iep_version.dart';

enum IepReviewAction { submit, returnForChanges, approve }
String iepReviewActionName(IepReviewAction action) => switch (action) {
  IepReviewAction.submit => 'submit',
  IepReviewAction.returnForChanges => 'return',
  IepReviewAction.approve => 'approve',
};
bool iepReviewActionFits(IepVersionStatus status, IepReviewAction action) =>
  action == IepReviewAction.submit
    ? status == IepVersionStatus.draft || status == IepVersionStatus.returned
    : status == IepVersionStatus.submitted;

/// Authored values must survive a review transition without silent edits.
Map<String, Object?> iepReviewContent(IepVersion v) => {
  'id': v.id, 'plan': v.planId, 'child': v.childId, 'number': v.number,
  'evaluation': v.evaluationId, 'summary': v.summary, 'author': v.author,
  'created': v.createdAt.toIso8601String(), 'start': v.start.toIso8601String(),
  'end': v.end.toIso8601String(), 'review': v.reviewOn.toIso8601String(),
  'accommodations': v.accommodations,
  'goals': [for (final g in v.goals) [g.id, g.versionId, g.title, g.baseline,
    g.target, g.unit, g.method, g.responsible, g.start.toIso8601String(), g.end.toIso8601String()]],
};
Map<String, Object?> _version(IepVersion v) => {
  ...iepReviewContent(v), 'status': v.status.name, 'reason': v.returnReason,
  'comments': [for (final c in v.comments) [c.id, c.versionId, c.text, c.author, c.createdAt.toIso8601String()]],
};
String iepReviewOtherVersions(IepPlan p, int versionId) => jsonEncode([
  for (final v in p.versions.where((v) => v.id != versionId)) _version(v),
]);

class IepReviewSource {
  IepReviewSource(this.plan, this.version) {
    if (plan.childId != version.childId || plan.id != version.planId ||
        !plan.versions.any((v) => identical(v, version))) {
      throw const FormatException('Foreign review version');
    }
  }
  final IepPlan plan;
  final IepVersion version;
  String get fingerprint => jsonEncode({
    'plan': plan.id, 'child': plan.childId, 'title': plan.title,
    'closed': plan.closed, 'approved': plan.currentApprovedId,
    'versions': [for (final v in plan.versions) _version(v)],
  });
  bool matches(IepPlan other) {
    final versions = other.versions.where((v) => v.id == version.id).toList();
    return versions.length == 1 && IepReviewSource(other, versions.single).fingerprint == fingerprint;
  }
}
class IepReviewOptions {
  IepReviewOptions(this.revision, Set<IepReviewAction> actions) : actions = Set.unmodifiable(actions);
  final String revision;
  final Set<IepReviewAction> actions;
}
