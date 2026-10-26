import '../enrollment/enrollment_models.dart';
import 'iep_version.dart';

class IepPlan {
  IepPlan._(
    this.id,
    this.childId,
    this.title,
    this.closed,
    this.currentApprovedId,
    this.versions,
  );
  final int id, childId;
  final String title;
  final bool closed;
  final int? currentApprovedId;
  final List<IepVersion> versions;
  factory IepPlan.fromJson(Map<String, dynamic> data) {
    final id = enrollmentId(data['id']), child = enrollmentId(data['child_id']);
    final current = data['current_approved_version_id'];
    if (!data.containsKey('current_approved_version_id') ||
        data['is_closed'] is! bool) {
      throw const FormatException('Missing IEP plan state');
    }
    final currentId = current == null ? null : enrollmentId(current);
    final versions = enrollmentList(data['versions'])
        .map((v) => IepVersion.fromJson(enrollmentMap(v)))
        .toList();
    if (versions.map((v) => v.id).toSet().length != versions.length ||
        versions.map((v) => v.number).toSet().length != versions.length ||
        versions.any((v) => v.planId != id || v.childId != child) ||
        (currentId != null &&
            !versions.any(
              (v) => v.id == currentId && v.status == IepVersionStatus.approved,
            ))) {
      throw const FormatException(
        'Invalid IEP plan scope or approved reference',
      );
    }
    versions.sort((a, b) => b.number.compareTo(a.number));
    return IepPlan._(
      id,
      child,
      enrollmentText(data['title']),
      data['is_closed'] as bool,
      currentId,
      List.unmodifiable(versions),
    );
  }
}

class IepPlanHistory {
  IepPlanHistory._(this.childId, this.plans);
  final int childId;
  final List<IepPlan> plans;
  factory IepPlanHistory.fromJson(int childId, Map<String, dynamic> data) {
    if (enrollmentId(data['child_id']) != childId)
      throw const FormatException('Foreign child');
    final plans = enrollmentList(data['plans'])
        .map((v) => IepPlan.fromJson(enrollmentMap(v)))
        .toList();
    final versions = plans.expand((plan) => plan.versions).toList();
    if (plans.map((v) => v.id).toSet().length != plans.length ||
        plans.any((v) => v.childId != childId) ||
        versions.map((v) => v.id).toSet().length != versions.length) {
      throw const FormatException('Invalid IEP history scope');
    }
    return IepPlanHistory._(childId, List.unmodifiable(plans));
  }
}
