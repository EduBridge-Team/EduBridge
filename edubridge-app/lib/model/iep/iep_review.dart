import 'iep_plan_history.dart';
import 'iep_snapshot.dart';
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
Map<String, Object?> iepReviewContent(IepVersion v) => iepVersionContent(v);
Map<String, Object?> _version(IepVersion v) => iepVersionSnapshot(v);
String iepReviewOtherVersions(IepPlan p, int versionId) => iepSnapshotFingerprint([
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
  String get fingerprint => iepSnapshotFingerprint(iepPlanSnapshot(plan));
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
