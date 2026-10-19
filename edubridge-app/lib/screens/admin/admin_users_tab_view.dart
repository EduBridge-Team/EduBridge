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
              context.sharedMessage(_error),
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
              label: Text(context.l10n.retryAction),
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
              label: Text(context.l10n.createInstitutionMinistryAccount),
            ),
            const SizedBox(height: 16),
          ],
          _buildSearchBar(c),
          const SizedBox(height: 16),
          _buildUserSection(
            icon: AppIcons.teacher, title: context.l10n.teachers,
            users: _teachers, color: AppColors.brandGreen, bgTint: c.tintGreen,
          ),
          _buildUserSection(
            icon: AppIcons.specialist, title: context.l10n.specialists,
            users: _specialists, color: AppColors.brandTealDeep, bgTint: c.tintOrange,
          ),
          _buildUserSection(
            icon: AppIcons.parent, title: context.l10n.parents,
            users: _parents, color: AppColors.brandBlue, bgTint: c.tintTeal,
          ),
          _buildUserSection(
            icon: Icons.business_outlined, title: context.l10n.institutions,
            users: _byRole('institution'), color: AppColors.brandBlue, bgTint: c.tintTeal,
          ),
          _buildUserSection(
            icon: Icons.account_balance_outlined, title: context.l10n.ministryRole,
            users: _byRole('ministry'), color: AppColors.brandTealDeep, bgTint: c.tintOrange,
          ),
          _buildChildrenSection(),
        ],
      ),
    );
  
  }
}
