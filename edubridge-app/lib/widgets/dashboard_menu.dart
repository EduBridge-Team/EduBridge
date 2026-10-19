// widgets/dashboard_menu.dart
import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'language_selector.dart';
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
  final double iconSize;
  final IconData menuIcon;
  final bool specialistFigmaMenu;
  final Color iconColor;

  const DashboardMenu({
    super.key,
    required this.actions,
    this.showMicrophoneToggle = false,
    this.badgeCount = 0,
    this.iconSize = 27,
    this.menuIcon = Icons.menu_rounded,
    this.specialistFigmaMenu = false,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
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
                      tooltip: strings.moreOptions,
                      color: Theme.of(context).colorScheme.surface,
                      surfaceTintColor: Colors.transparent,
                      elevation: 8,
                      position: PopupMenuPosition.under,
                      constraints: specialistFigmaMenu
                          ? const BoxConstraints(minWidth: 230, maxWidth: 230)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.45),
                        ),
                      ),
                      icon: Badge(
                        isLabelVisible: count > 0 && !specialistFigmaMenu,
                        label: Text('$count'),
                        child: Icon(
                          menuIcon,
                          color: iconColor,
                          size: iconSize,
                        ),
                      ),
                      onSelected: (value) async {
                        if (value == '_language') {
                          await showLanguageSelector(context);
                          return;
                        }
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
                        PopupMenuItem<String>(
                          value: '_language',
                          child: _MenuRow(icon: Icons.language, label: strings.language),
                        ),
                        if (specialistFigmaMenu) ...[
                              PopupMenuItem<String>(
                                value: 'specialist_lessons',
                                height: 46,
                                child: _SpecialistFigmaMenuRow(
                                  icon: Icons.menu_book_outlined,
                                  label: strings.lessons,
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'support',
                                height: 46,
                                child: _SpecialistFigmaMenuRow(
                                  icon: Icons.headset_mic_outlined,
                                  label: strings.technicalSupport,
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: '_assistant',
                                height: 46,
                                child: _SpecialistFigmaMenuRow(
                                  icon: assistantVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  label: assistantVisible ? strings.hideNoor : strings.showNoor,
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'about_app',
                                height: 46,
                                child: _SpecialistFigmaMenuRow(
                                  icon: Icons.info_outline,
                                  label: strings.aboutApp,
                                ),
                              ),
                            ]
                          else ...[
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
                                ? strings.switchToLightMode
                                : strings.switchToDarkMode,
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: '_assistant',
                          child: _MenuRow(
                            icon: assistantVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            label: assistantVisible
                                ? strings.hideNoor
                                : strings.showNoor,
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
                                  ? strings.hideMicrophone
                                  : strings.showMicrophone,
                            ),
                          ),
                      ],
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
    final c = JisrColors.of(context);
    final normalIconColor =
        isDark ? AppColors.lightTeal : AppColors.navyDeep;
    final normalTextColor = Theme.of(context).colorScheme.onSurface;
    final color = destructive ? c.dangerText : normalTextColor;

    return Row(
      children: [
        Icon(
          icon,
          color: destructive ? c.dangerText : normalIconColor,
          size: 23,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}


/// Compact specialist overflow rows matching the S03 Figma reference.
class _SpecialistFigmaMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SpecialistFigmaMenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFF176CCC), size: 21),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
