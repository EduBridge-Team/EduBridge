// lib/widgets/notification_snackbar.dart
import 'package:flutter/material.dart';
import '../services/notification_listener_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../utils/navigation.dart';

class NotificationSnackbarHost extends StatefulWidget {
  final Widget child;
  const NotificationSnackbarHost({super.key, required this.child});

  @override
  State<NotificationSnackbarHost> createState() =>
      _NotificationSnackbarHostState();
}

class _NotificationSnackbarHostState extends State<NotificationSnackbarHost> {
  int? _lastShownId;

  @override
  void initState() {
    super.initState();
    NotificationListenerService.instance.latestNotification
        .addListener(_onNotification);
  }

  @override
  void dispose() {
    NotificationListenerService.instance.latestNotification
        .removeListener(_onNotification);
    super.dispose();
  }

  void _onNotification() {
    final notif =
        NotificationListenerService.instance.latestNotification.value;
    if (notif == null) return;

    final id = notif['id'] as int?;
    if (id != null && _lastShownId == id) return;
    _lastShownId = id;

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _show(notif);
    });
  }

  void _show(Map<String, dynamic> notif) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final icon = _iconFor(notif['type']);
    final title = (notif['title'] ?? '').toString();
    final body = (notif['body'] ?? '').toString();
    final c = JisrColors.of(context);

    TtsService.instance.speakLine('$title. $body');

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: c.card,
        content: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: c.body,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'عرض',
          textColor: AppColors.tealDeep,
          onPressed: () {
            final nav = appNavigatorKey.currentState;
            if (nav == null) return;
            nav.pushNamed('/notifications');
          },
        ),
      ),
    );
  }

  // أيقونات إشعارات الدعم التعليمي
  String _iconFor(String? type) {
    switch (type) {
      case 'homework_assigned':
        return '📝';
      case 'homework_submitted':
        return '📥';
      case 'homework_submitted_late':
        return '⏰';
      case 'homework_graded':
        return '⭐';
      case 'plan_approved':
        return '✅';
      case 'plan_rejected':
        return '❌';
      case 'plan_submitted':
        return '📤';
      case 'child_added':
        return '👶';
      case 'child_evaluated':
        return '📋';
      case 'child_assigned':
        return '👨‍🏫';
      case 'lesson_added':
        return '📚';
      case 'weekly_report_created':
        return '📊';
      case 'specialist_progress_created':
        return '🧠';
      case 'plan_evaluation_created':
        return '📋';
      case 'learning_support_meeting_scheduled':
        return '🗓️';
      // طلبات الدعم التعليمي
      case 'learning_support_request_created':
        return '🧠';
      case 'learning_support_scheduled':
        return '📅';
      case 'learning_support_request_cancelled':
        return '❌';
      case 'specialist_suggestion':
         return '🤝';
      case 'suggestion_accepted':
        return '✅';
      case 'suggestion_rejected':
         return '❌';  
      default:
        return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}