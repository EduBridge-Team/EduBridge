part of 'ministry_screen.dart';

extension _MinistryUsersTabStateView on _MinistryUsersTabState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.sharedMessage(_error),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: Text(context.l10n.retryAction)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.tintTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.view, color: AppColors.brandBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.ministryReadOnlyNotice,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.onTint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: context.l10n.searchNameOrEmail,
                prefixIcon: Icon(AppIcons.search),
                border: InputBorder.none,
              ),
              onChanged: (v) => _refreshState(() => _search = v),
            ),
          ),
          const SizedBox(height: 16),
          _buildMinistryUserSection(
            context: context,
            icon: AppIcons.teacher,
            title: context.l10n.teachers,
            users: _teachers,
            color: AppColors.brandBlueLight,
            bgTint: c.tintGreen,
            childrenForUser: _childrenForUser,
          ),
          _buildMinistryUserSection(
            context: context,
            icon: AppIcons.specialist,
            title: context.l10n.specialists,
            users: _specialists,
            color: AppColors.brandTealDeep,
            bgTint: c.tintOrange,
            childrenForUser: _childrenForUser,
          ),
          _buildMinistryUserSection(
            context: context,
            icon: AppIcons.parent,
            title: context.l10n.parents,
            users: _parents,
            color: AppColors.brandBlue,
            bgTint: c.tintTeal,
            childrenForUser: _childrenForUser,
          ),
        ],
      ),
    );
  
  }
}
