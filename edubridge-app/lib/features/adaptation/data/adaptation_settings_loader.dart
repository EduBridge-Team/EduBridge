import '../../../services/accessibility_service.dart';
import 'adaptation_permission_repository.dart';

/// Editing is ready only after both child preferences and server permission load.
class AdaptationSettingsLoader {
  AdaptationSettingsLoader({
    AdaptationPermissionRepository? permissions,
    Future<void> Function(int childId, String? disabilityHint)? activateChild,
  }) : _permissions = permissions ?? AdaptationPermissionRepository(),
       _activateChild = activateChild ?? _activateSavedChild;

  final AdaptationPermissionRepository _permissions;
  final Future<void> Function(int, String?) _activateChild;

  static Future<void> _activateSavedChild(int childId, String? hint) =>
      AccessibilityService.instance.setActiveChild(childId,
        disabilityTypeHint: hint, forceReload: true);

  Future<bool> load(int childId, {String? disabilityHint}) async {
    final profileReady = _activateChild(childId, disabilityHint);
    final permission = _permissions.canEdit(childId);
    final results = await Future.wait<bool>([profileReady.then((_) => true), permission]);
    return results[1];
  }
}
