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
  final actions = menuActions;

  return BrandDashboardHeader(child: Row(
              children: [
                const ProfileAvatarButton(
                  size: 48,
                  showVerificationBadge: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF1768C5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: tabIndex == 1
                      ? Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            context.l10n.lessons,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : FutureBuilder<String?> (
                    future: ApiService.getName(),
                    builder: (context, snapshot) {
                      final name = snapshot.data?.trim();
                      return Column(mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name == null || name.isEmpty ? context.l10n.specialistRole : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _subtitleFor(context, tabIndex, specialty),
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
                ValueListenableBuilder<int>(
                  valueListenable:
                      NotificationListenerService.instance.unreadCount,
                  builder: (context, unreadCount, _) => Material(
                    color: Colors.white.withValues(alpha: .16),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: context.l10n.notifications,
                      icon: Badge(
                        isLabelVisible: unreadCount > 0,
                        smallSize: 9,
                        backgroundColor: const Color(0xFFE94C60),
                        child: const Icon(
                          AppIcons.notifications,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                DashboardMenu(
                  actions: actions,
                  iconSize: 25,
                  menuIcon: Icons.more_vert,
                  specialistFigmaMenu: true,
                  iconColor: Colors.white,
                ),
              ],
            ));
}

String _subtitleFor(BuildContext context, int tabIndex, String? specialty) {
  if (tabIndex == 1) return context.l10n.lessons;
  switch (specialty) {
    case 'learning_support':
      return context.l10n.learningSupportSpecialist;
    case 'educational':
      return context.l10n.educationalSpecialist;
    default:
      return context.l10n.specialistRole;
  }
}
