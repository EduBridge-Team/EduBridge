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
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
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
          _buildSearchBar(c),
          const SizedBox(height: 16),
          _buildUserSection(
            icon: AppIcons.teacher, title: 'المعلّمون',
            users: _teachers, color: AppColors.greenDeep, bgTint: c.tintGreen,
          ),
          _buildUserSection(
            icon: AppIcons.specialist, title: 'المختصون',
            users: _specialists, color: AppColors.brandTealDeep, bgTint: c.tintOrange,
          ),
          _buildUserSection(
            icon: AppIcons.parent, title: 'أولياء الأمور',
            users: _parents, color: AppColors.brandBlue, bgTint: c.tintTeal,
          ),
          _buildChildrenSection(),
        ],
      ),
    );
  
  }
}
