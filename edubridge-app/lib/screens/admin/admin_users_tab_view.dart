part of 'admin_screen.dart';

extension _UsersTabStateView on _UsersTabState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _StateBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.error, color: AppColors.red, size: 52),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.red,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          if ((widget.admin['role'] ?? '').toString() == 'admin') ...[
            FilledButton.icon(
              onPressed: _openCreateAccount,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('إنشاء حساب مؤسسة أو وزارة'),
            ),
            const SizedBox(height: 16),
          ],
          _buildSearchBar(c),
          const SizedBox(height: 16),
          _buildUserSection(
            icon: AppIcons.teacher, title: 'المعلّمون',
            users: _teachers, color: AppColors.brandGreen, bgTint: c.tintGreen,
          ),
          _buildUserSection(
            icon: AppIcons.specialist, title: 'المختصون',
            users: _specialists, color: AppColors.brandTealDeep, bgTint: c.tintOrange,
          ),
          _buildUserSection(
            icon: AppIcons.parent, title: 'أولياء الأمور',
            users: _parents, color: AppColors.brandBlue, bgTint: c.tintTeal,
          ),
          _buildUserSection(
            icon: Icons.business_outlined, title: 'المؤسسات',
            users: _byRole('institution'), color: AppColors.brandBlue, bgTint: c.tintTeal,
          ),
          _buildUserSection(
            icon: Icons.account_balance_outlined, title: 'الوزارة',
            users: _byRole('ministry'), color: AppColors.brandTealDeep, bgTint: c.tintOrange,
          ),
          _buildChildrenSection(),
        ],
      ),
    );
  
  }
}
