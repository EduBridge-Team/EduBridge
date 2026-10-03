// lib/screens/specialist/specialist_header.dart
part of 'specialist_screen.dart';

Widget _buildHeader({
  required BuildContext context,
  required JisrColors c,
  required int tabIndex,
  required String? specialty,
  required List<DashboardMenuAction> menuActions,
}) {
  final actions = <DashboardMenuAction>[
    DashboardMenuAction(
      id: 'notifications',
      label: 'الإشعارات',
      icon: AppIcons.notifications,
      onSelected: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      ),
    ),
    ...menuActions,
  ];

  return Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: AppColors.headerGradient,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DashboardMenu(
                  actions: actions,
                  iconSize: 26,
                  iconColor: Colors.white,
                ),
                const Spacer(),
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/brand_logo.png',
                    width: 124,
                    height: 34,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FutureBuilder<String?>(
              future: ApiService.getName(),
              builder: (context, snap) {
                final name = snap.data ?? 'المختص';
                return Row(
                  children: [
                    const ProfileAvatarButton(
                      size: 54,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brandTealDeep,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً، $name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _subtitleFor(tabIndex, specialty),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

String _subtitleFor(int tabIndex, String? specialty) {
  if (tabIndex == 1) {
    return 'دروس إرشادية للأطفال وأولياء الأمور';
  }

  switch (specialty) {
    case 'learning_support':
      return 'مختص دعم تعليمي • متابعة الأطفال والتقدم';
    case 'educational':
      return 'مختص تعليمي • متابعة الأطفال والتقدم';
    default:
      return 'متابعة الأطفال والتقييم والتقدم';
  }
}
