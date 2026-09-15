// شاشة الإشعارات — نسخة موحّدة (مشتركة بين جميع الأدوار)
// تُستخدم من: parent_screen، teacher_screen، speclalist_screen، admin_screen
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/speakable.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List _notifications = [];
  bool _loading = true;
  bool _markingAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notifications = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
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
      setState(() {
        _notifications = _notifications.map((n) {
          if (n['id'] == id) n['is_read'] = true;
          return n;
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);

    try {
      await ApiService.markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((n) => {...n, 'is_read': true})
            .toList();
      });
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
      default:
        return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final hasUnread = _notifications.any((n) => n['is_read'] != true);

    return Scaffold(
      appBar: JisrAppBar(
        title: 'الإشعارات',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _loading ? null : _loadNotifications,
          ),
          if (hasUnread)
            TextButton(
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
                      'تحديد الكل كمقروء',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
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
              onPressed: _loadNotifications,
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
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
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _notifications.length,
        itemBuilder: (context, i) => _buildTile(_notifications[i], c),
      ),
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
          onTap: () => _markRead(n['id']),
        ),
      ),
    );
  }
}