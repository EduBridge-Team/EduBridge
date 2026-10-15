// Specialist header styled to match the Figma reference.
// Keep the existing menu and notification navigation intact.
part of 'specialist_screen.dart';

Widget _buildHeader({
  required BuildContext context,
  required JisrColors c,
  required int tabIndex,
  required String? specialty,
  required List<DashboardMenuAction> menuActions,
}) {
  final textTheme = Theme.of(context).textTheme;
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
      gradient: LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF1559B3), Color(0xFF1B74CA), Color(0xFF1EB8C4)],
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    child: Stack(
      children: [
        Positioned(
          left: -56,
          bottom: -92,
          child: IgnorePointer(
            child: Container(
              width: 190,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .19),
                  width: 17,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: -30,
          bottom: -94,
          child: IgnorePointer(
            child: Container(
              width: 138,
              height: 142,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .17),
                  width: 14,
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Row(
              children: [
                const ProfileAvatarButton(
                  size: 48,
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF1768C5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<String?>(
                    future: ApiService.getName(),
                    builder: (context, snapshot) {
                      final name = snapshot.data?.trim();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name == null || name.isEmpty ? 'المختص' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _subtitleFor(tabIndex, specialty),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: .87),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                DashboardMenu(
                  actions: actions,
                  iconSize: 25,
                  iconColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

String _subtitleFor(int tabIndex, String? specialty) {
  if (tabIndex == 1) return 'الدروس';
  switch (specialty) {
    case 'learning_support':
      return 'مختص دعم تعليمي';
    case 'educational':
      return 'مختص تعليمي';
    default:
      return 'مختص';
  }
}
