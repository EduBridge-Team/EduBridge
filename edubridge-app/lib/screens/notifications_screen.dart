// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_listener_service.dart';
import '../theme.dart';
import '../widgets/speakable.dart';
import 'specialist_suggestions_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  bool _markingAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await NotificationListenerService.instance.reloadAll();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل الإشعارات';
        _loading = false;
      });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await ApiService.markNotificationRead(id);
      if (!mounted) return;

      final current = NotificationListenerService.instance.notifications.value;
      NotificationListenerService.instance.notifications.value =
          current.map((n) {
        if (n['id'] == id) {
          return {...n as Map, 'is_read': true};
        }
        return n;
      }).toList();

      await NotificationListenerService.instance.refresh();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);

    try {
      await ApiService.markAllNotificationsRead();
      if (!mounted) return;

      final current = NotificationListenerService.instance.notifications.value;
      NotificationListenerService.instance.notifications.value =
          current.map((n) => {...n as Map, 'is_read': true}).toList();

      await NotificationListenerService.instance.refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديد جميع الإشعارات كمقروءة')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تنفيذ العملية')),
      );
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  // أيقونات إشعارات الدعم التعليمي
  String _getIcon(String type) {
    switch (type) {
      case 'child_added':
        return '👶';
      case 'child_evaluated':
        return '📋';
      case 'child_assigned':
        return '👨‍🏫';
      case 'lesson_added':
        return '📚';
      case 'plan_approved':
        return '✅';
      case 'plan_rejected':
        return '❌';
      case 'plan_submitted':
        return '📤';
      case 'homework_assigned':
        return '📝';
      case 'homework_submitted':
        return '📥';
      case 'homework_submitted_late':
        return '⏰';
      case 'homework_graded':
        return '⭐';
      case 'weekly_report_created':
        return '📊';
      case 'specialist_progress_created':
        return '🧠';
      case 'plan_evaluation_created':
        return '📋';
      case 'learning_support_meeting_scheduled':
        return '🗓️';
      // ✅ جديد
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
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(
        title: 'الإشعارات',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _loading ? null : _load,
          ),
          ValueListenableBuilder<int>(
            valueListenable: NotificationListenerService.instance.unreadCount,
            builder: (context, count, _) {
              if (count == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: _markingAll ? null : _markAllRead,
                child: _markingAll
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'تحديد الكل',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(c),
    );
  }

  Widget _buildBody(JisrColors c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: NotificationListenerService.instance.notifications,
      builder: (context, list, _) {
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 64, color: c.muted),
                const SizedBox(height: 16),
                Text(
                  'لا توجد إشعارات',
                  style: TextStyle(fontSize: 18, color: c.muted),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) => _buildTile(list[i] as Map, c),
          ),
        );
      },
    );
  }

  Widget _buildTile(Map n, JisrColors c) {
    final isRead = n['is_read'] ?? false;
    final date = n['created_at'] != null
        ? DateTime.tryParse(n['created_at'].toString())
        : null;
    final title = (n['title'] ?? '').toString();
    final body = (n['body'] ?? '').toString();

    return Speakable(
      text: '$title: $body',
      onTap: () => _markRead(n['id']),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: isRead ? null : c.tintTeal.withValues(alpha: 0.3),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Text(
            _getIcon(n['type']?.toString() ?? ''),
            style: const TextStyle(fontSize: 28),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              color: c.heading,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(body, style: TextStyle(color: c.body)),
              if (date != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${date.day}/${date.month}/${date.year} '
                    '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 11, color: c.muted),
                  ),
                ),
            ],
          ),
          trailing: isRead
              ? null
              : Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            onTap: () {
          _markRead(n['id']);
          final type = n['type']?.toString();
          if (type == 'specialist_suggestion' ||
              type == 'suggestion_accepted' ||
              type == 'suggestion_rejected') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SpecialistSuggestionsScreen(),
              ),

            );
              }
            }
        )
        
      ),
    );
  }
}