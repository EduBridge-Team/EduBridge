// lib/screens/ministry/ministry_overview_tab.dart
part of 'ministry_screen.dart';

class _MinistryOverviewTab extends StatefulWidget {
  const _MinistryOverviewTab();

  @override
  State<_MinistryOverviewTab> createState() => _MinistryOverviewTabState();
}

class _MinistryOverviewTabState extends State<_MinistryOverviewTab> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await ApiService.getMinistryStats();
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    final totalChildren = _stats?['children_count'] ?? 0;
    final totalUsers = _stats?['users_count'] ?? 0;
    final pendingApprovals = _stats?['pending_approvals'] ?? 0;
    final schools = _stats?['schools_count'] ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _MinistryInfoCard(
                icon: AppIcons.child, value: '$totalChildren',
                label: 'طفل', tint: c.tintTeal,
              ),
              const SizedBox(width: 10),
              _MinistryInfoCard(
                icon: AppIcons.users, value: '$totalUsers',
                label: 'مستخدم', tint: c.tintGreen,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MinistryInfoCard(
                icon: AppIcons.upload, value: '$pendingApprovals',
                label: 'طلب معلّق', tint: c.tintOrange,
              ),
              const SizedBox(width: 10),
              _MinistryInfoCard(
                icon: AppIcons.institution, value: '$schools',
                label: 'مؤسسة', tint: c.tintYellow,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'أدوات الإدارة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _MinistryMenuTile(
            icon: AppIcons.lesson, tint: c.tintTeal,
            title: 'تصفح الدروس',
            subtitle: 'عرض جميع الدروس المضافة',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LessonsScreen()),
            ),
          ),
          _MinistryMenuTile(
            icon: AppIcons.search, tint: c.tintGreen,
            title: 'البحث بالهوية',
            subtitle: 'البحث عن طالب أو مستخدم',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchByIdentityScreen()),
            ),
          ),
          _MinistryMenuTile(
            icon: AppIcons.report, tint: c.tintOrange,
            title: 'التقارير الشهرية',
            subtitle: 'إحصائيات مفصّلة (قريباً)',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قريباً')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MinistryInfoCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  const _MinistryInfoCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 22, color: AppColors.brandBlue),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinistryMenuTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MinistryMenuTile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 26, color: AppColors.brandBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13.5, color: c.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}