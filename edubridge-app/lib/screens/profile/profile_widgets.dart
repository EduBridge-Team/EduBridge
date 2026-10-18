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
          Text(_error!,
              style: const TextStyle(color: AppColors.red, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(AppIcons.refresh),
            label: const Text('إعادة المحاولة'),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'parent':
        return 'ولي أمر';
      case 'teacher':
        return 'معلّم';
      case 'specialist':
        return 'مختص';
      case 'admin':
        return 'أدمن';
      case 'ministry':
        return 'وزارة';
      case 'institution':
        return 'مؤسسة';
      default:
        return role.isEmpty ? 'مستخدم' : role;
    }
  }
}
