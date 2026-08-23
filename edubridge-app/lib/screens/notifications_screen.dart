// شاشة الإشعارات
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
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذّر تحميل الإشعارات';
        _loading = false;
      });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await ApiService.markNotificationRead(id);
      setState(() {
        _notifications = _notifications.map((n) {
          if (n['id'] == id) {
            n['is_read'] = true;
          }
          return n;
        }).toList();
      });
    } catch (_) {}
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
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _notifications.isEmpty
                  ? Center(
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
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _notifications.length,
                      itemBuilder: (context, i) {
                        final n = _notifications[i];
                        final isRead = n['is_read'] ?? false;
                        final date = n['created_at'] != null
                            ? DateTime.parse(n['created_at'])
                            : null;

                        return Speakable(
                          text: '${n['title'] ?? ''}: ${n['body'] ?? ''}',
                          onTap: () => _markRead(n['id']),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isRead ? null : c.tintTeal.withValues(alpha: 0.3),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Text(
                                _getIcon(n['type'] ?? ''),
                                style: const TextStyle(fontSize: 28),
                              ),
                              title: Text(
                                n['title'] ?? '',
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                  color: c.heading,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n['body'] ?? '',
                                    style: TextStyle(color: c.body),
                                  ),
                                  if (date != null)
                                    Text(
                                      '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: c.muted,
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
                      },
                    ),
    );
  }
}