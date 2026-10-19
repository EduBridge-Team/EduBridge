import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../l10n/generated/app_localizations.dart';
import '../screens/notifications_screen.dart';
import '../services/notification_listener_service.dart';
import 'dashboard_menu.dart';

/// Shared specialist-style controls; each dashboard supplies its own actions.
class DashboardHeaderActions extends StatelessWidget {
  const DashboardHeaderActions({
    super.key,
    required this.actions,
    this.showMicrophoneToggle = false,
  });

  final List<DashboardMenuAction> actions;
  final bool showMicrophoneToggle;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ValueListenableBuilder<int>(
        valueListenable: NotificationListenerService.instance.unreadCount,
        builder: (context, unreadCount, _) => Material(
          color: Colors.white.withValues(alpha: .16),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: AppLocalizations.of(context).notifications,
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              smallSize: 9,
              backgroundColor: const Color(0xFFE94C60),
              child: const Icon(AppIcons.notifications,
                  color: Colors.white, size: 24),
            ),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ),
      ),
      const SizedBox(width: 6),
      DashboardMenu(
        actions: actions,
        showMicrophoneToggle: showMicrophoneToggle,
        iconSize: 25,
        menuIcon: Icons.more_vert,
        specialistFigmaMenu: true,
        iconColor: Colors.white,
      ),
    ],
  );
}
