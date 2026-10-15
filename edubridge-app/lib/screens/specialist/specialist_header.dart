part of 'specialist_screen.dart';

Widget _buildHeader({
  required BuildContext context,
  required JisrColors c,
  required int tabIndex,
  required String? specialty,
  required List<DashboardMenuAction> menuActions,
}) {
  return Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [AppColors.brandBlue, AppColors.brandBlueDeep],
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: Stack(
      children: [
        PositionedDirectional(
          start: -65,
          bottom: -95,
          child: IgnorePointer(
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.brandTeal.withValues(alpha: .25),
                  width: 24,
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            child: Row(
              children: [
                const ProfileAvatarButton(
                  size: 48,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.brandBlue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FutureBuilder<String?>(
                    future: ApiService.getName(),
                    builder: (context, snapshot) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          snapshot.data ?? 'المختص',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialty == 'learning_support'
                              ? 'مختص دعم تعليمي'
                              : specialty == 'educational'
                                  ? 'مختص تعليمي'
                                  : 'المختص',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'الإشعارات',
                  icon: const Icon(AppIcons.notifications, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
                DashboardMenu(actions: menuActions, iconColor: Colors.white),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
