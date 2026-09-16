// widgets/dashboard_menu.dart
import 'package:flutter/material.dart';
import '../services/notification_listener_service.dart';
import '../services/overlay_visibility_service.dart';
import '../services/user_settings_sync_service.dart';
import '../theme.dart';

class DashboardMenuAction {
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool destructive;

  const DashboardMenuAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onSelected,
    this.destructive = false,
  });
}

class DashboardMenu extends StatelessWidget {
  final List<DashboardMenuAction> actions;
  final bool showMicrophoneToggle;
  final int badgeCount;

  const DashboardMenu({
    super.key,
    required this.actions,
    this.showMicrophoneToggle = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OverlayVisibilityService.assistantVisible,
      builder: (context, assistantVisible, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: OverlayVisibilityService.microphoneVisible,
          builder: (context, microphoneVisible, _) {
            return ValueListenableBuilder<ThemeMode>(
              valueListenable: jisrThemeMode,
              builder: (context, themeMode, _) {
                return ValueListenableBuilder<int>(
                  valueListenable:
                      NotificationListenerService.instance.unreadCount,
                  builder: (context, liveCount, _) {
                    final count = liveCount > 0 ? liveCount : badgeCount;
                    final isDark = themeMode == ThemeMode.dark;

                    return PopupMenuButton<String>(
                      tooltip: 'القائمة',
                      color: Theme.of(context).colorScheme.surface,
                      surfaceTintColor: Colors.transparent,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.45),
                        ),
                      ),
                      icon: Badge(
                        isLabelVisible: count > 0,
                        label: Text('$count'),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                        ),
                      ),
                      onSelected: (value) async {
                        if (value == '_theme') {
                          await toggleThemeMode();
                          await UserSettingsSyncService.pushCurrent();
                          return;
                        }
                        if (value == '_assistant') {
                          await OverlayVisibilityService.setAssistantVisible(
                            !assistantVisible,
                          );
                          await UserSettingsSyncService.pushCurrent();
                          return;
                        }
                        if (value == '_microphone') {
                          await OverlayVisibilityService.setMicrophoneVisible(
                            !microphoneVisible,
                          );
                          await UserSettingsSyncService.pushCurrent();
                          return;
                        }
                        for (final action in actions) {
                          if (action.id == value) {
                            action.onSelected();
                            return;
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        for (final action in actions)
                          PopupMenuItem<String>(
                            value: action.id,
                            child: _MenuRow(
                              icon: action.icon,
                              label: action.label,
                              destructive: action.destructive,
                            ),
                          ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: '_theme',
                          child: _MenuRow(
                            icon: isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            label: isDark
                                ? 'التبديل للوضع الفاتح'
                                : 'التبديل للوضع الداكن',
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: '_assistant',
                          child: _MenuRow(
                            icon: assistantVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            label: assistantVisible
                                ? 'إخفاء نور'
                                : 'إظهار نور',
                          ),
                        ),
                        if (showMicrophoneToggle)
                          PopupMenuItem<String>(
                            value: '_microphone',
                            child: _MenuRow(
                              icon: microphoneVisible
                                  ? Icons.mic_off_outlined
                                  : Icons.mic_none_outlined,
                              label: microphoneVisible
                                  ? 'إخفاء المايك'
                                  : 'إظهار المايك',
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalIconColor =
        isDark ? AppColors.lightTeal : AppColors.navyDeep;
    final normalTextColor = Theme.of(context).colorScheme.onSurface;
    final color = destructive ? AppColors.red : normalTextColor;

    return Row(
      children: [
        Icon(
          icon,
          color: destructive ? AppColors.red : normalIconColor,
          size: 23,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
