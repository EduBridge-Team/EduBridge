// widgets/dashboard_menu.dart
import 'package:flutter/material.dart';
import '../services/notification_listener_service.dart';
import '../services/overlay_visibility_service.dart';

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
            return ValueListenableBuilder<int>(
              valueListenable: NotificationListenerService.instance.unreadCount,
              builder: (context, liveCount, _) {
                final count = liveCount > 0 ? liveCount : badgeCount;
                return PopupMenuButton<String>(
                  tooltip: 'القائمة',
                  icon: Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: const Icon(Icons.menu_rounded,
                        color: Colors.white),
                  ),
                  onSelected: (value) {
                    if (value == '_assistant') {
                      OverlayVisibilityService.setAssistantVisible(
                        !assistantVisible,
                      );
                      return;
                    }
                    if (value == '_microphone') {
                      OverlayVisibilityService.setMicrophoneVisible(
                        !microphoneVisible,
                      );
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
    final color = destructive ? Colors.red : null;
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}