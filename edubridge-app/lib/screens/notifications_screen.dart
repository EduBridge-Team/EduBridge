// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../services/notification_listener_service.dart';
import '../theme.dart';
import '../widgets/speakable.dart';
import 'specialist_suggestions_screen.dart';
part 'notifications_screen_view.dart';

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
      if (!mounted) return;

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

  IconData _getIcon(String type) {
    switch (type) {
      case 'child_added':
        return AppIcons.child;
      case 'child_evaluated':
        return AppIcons.evaluate;
      case 'child_assigned':
        return AppIcons.teacher;
      case 'lesson_added':
        return AppIcons.lesson;
      case 'plan_approved':
        return AppIcons.check;
      case 'plan_rejected':
        return AppIcons.error;
      case 'plan_submitted':
        return AppIcons.upload;
      case 'homework_assigned':
        return AppIcons.homework;
      case 'homework_submitted':
        return AppIcons.download;
      case 'homework_submitted_late':
        return AppIcons.clock;
      case 'homework_graded':
        return AppIcons.starFilled;
      case 'weekly_report_created':
        return AppIcons.report;
      case 'specialist_progress_created':
        return AppIcons.specialist;
      case 'plan_evaluation_created':
        return AppIcons.evaluate;
      case 'learning_support_meeting_scheduled':
        return AppIcons.event;
      case 'learning_support_request_created':
        return AppIcons.specialist;
      case 'learning_support_scheduled':
        return AppIcons.calendar;
      case 'learning_support_request_cancelled':
        return AppIcons.error;
      case 'specialist_suggestion':
        return AppIcons.users;
      case 'suggestion_accepted':
        return AppIcons.check;
      case 'suggestion_rejected':
        return AppIcons.error;
      default:
        return AppIcons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'plan_approved':
      case 'suggestion_accepted':
      case 'homework_graded':
        return AppColors.green;
      case 'plan_rejected':
      case 'suggestion_rejected':
      case 'learning_support_request_cancelled':
        return AppColors.red;
      case 'homework_submitted_late':
        return AppColors.orangeDeep;
      case 'learning_support_scheduled':
      case 'learning_support_meeting_scheduled':
        return AppColors.brandTeal;
      default:
        return AppColors.brandBlue;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير متوفر';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} • ${date.hour}:$minute';
  }

  Future<void> _openNotificationDetails(Map n, JisrColors c) async {
    final id = n['id'];
    if (id is int) {
      await _markRead(id);
    }
    if (!mounted) return;

    final title = (n['title'] ?? 'تفاصيل الإشعار').toString();
    final body = (n['body'] ?? '').toString();
    final type = n['type']?.toString() ?? '';
    final date = n['created_at'] != null
        ? DateTime.tryParse(n['created_at'].toString())
        : null;
    final canOpenSuggestion = type == 'specialist_suggestion' ||
        type == 'suggestion_accepted' ||
        type == 'suggestion_rejected';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: c.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _getIconColor(type).withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _getIcon(type),
                      color: _getIconColor(type),
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 19,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                        color: c.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.tintTeal.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    body,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.65,
                      color: c.body,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 17, color: c.muted),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
              if (canOpenSuggestion) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SpecialistSuggestionsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('فتح التفاصيل المرتبطة'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => buildView(context);

  Widget _buildBody(JisrColors c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(AppIcons.error, size: 56, color: AppColors.red),
          const SizedBox(height: 14),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton.icon(
              icon: const Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ),
        ],
      );
    }

    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: NotificationListenerService.instance.notifications,
      builder: (context, list, _) {
        if (list.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 110),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: c.tintTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.notifications,
                    size: 40,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'لا توجد إشعارات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: c.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ستظهر التحديثات المهمة هنا عند وصولها.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: c.muted),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
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
    final type = n['type']?.toString() ?? '';
    final icon = _getIcon(type);
    final iconColor = _getIconColor(type);

    return Speakable(
      text: '$title: $body',
      onTap: () => _markRead(n['id']),
      child: Material(
        color: isRead ? c.card : c.tintTeal.withValues(alpha: .35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openNotificationDetails(n, c),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 23, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.w700
                                    : FontWeight.w800,
                                color: c.heading,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.brandBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: c.body,
                          ),
                        ),
                      ],
                      if (date != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: c.muted),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(date),
                              style: TextStyle(fontSize: 11, color: c.muted),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_left_rounded,
                              size: 18,
                              color: c.muted,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}