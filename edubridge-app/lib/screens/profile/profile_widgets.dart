// Profile presentation widgets extracted from profile_screen.dart.
part of 'profile_screen.dart';

extension _ProfileWidgetsExtension on _ProfileScreenState {
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(AppIcons.error, size: 64, color: AppColors.red),
          const SizedBox(height: 16),
          Text(context.sharedMessage(_error),
              style: const TextStyle(color: AppColors.red, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(AppIcons.refresh),
            label: Text(context.l10n.retryAction),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'parent':
        return context.l10n.parentRole;
      case 'teacher':
        return context.l10n.teacherRole;
      case 'specialist':
        return context.l10n.specialistRole;
      case 'admin':
        return context.l10n.adminRole;
      case 'ministry':
        return context.l10n.ministryRole;
      case 'institution':
        return context.l10n.institutionRole;
      default:
        return role.isEmpty ? context.l10n.user : role;
    }
  }
}
