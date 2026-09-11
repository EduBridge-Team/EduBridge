// شاشة ولي الأمر — إدارة الأطفال + الألعاب حسب العمر
import 'dart:convert';
import 'package:edubridge_app/screens/add_certificate_sheet.dart';
import 'package:edubridge_app/screens/chats_screen.dart';
import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'notifications_screen.dart';
import 'support_sheet.dart';
import 'child_lessons_screen.dart';
import 'child_progress_screen.dart';
import 'add_child_screen.dart';
import 'edit_child_screen.dart';
import 'children_accessibility_overview_screen.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key, required Map<dynamic, dynamic> parent});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  List _children = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadNotificationsCount();
  }

  @override
  void dispose() {
    AccessibilityService.instance.setActiveChild(null);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.authGet('/children');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          _children = data['children'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error'] ?? 'تعذّر جلب الأطفال';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  Future<void> _loadNotificationsCount() async {
    try {
      final count = await ApiService.getUnreadNotificationsCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (_) {}
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'evaluated':
        return 'تم التقييم ✓';
      case 'assigned':
        return 'تم التعيين ✓';
      default:
        return 'قيد الانتظار ⏳';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'evaluated':
        return AppColors.green;
      case 'assigned':
        return AppColors.teal;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
          ),
        ),
        title: Row(
          children: [
            Image.asset('assets/icon.png', width: 26, height: 26),
            const SizedBox(width: 8),
            const Text(
              'جسر التعليمي',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          _appBarIcon(
            icon: Icons.accessibility_new,
            tooltip: 'احتياجات الأبناء',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ChildrenAccessibilityOverviewScreen(),
              ),
            ),
          ),
          _appBarIcon(
            icon: Icons.headset_mic,
            tooltip: 'الدعم الفني',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const SupportSheet(),
            ),
          ),
          _appBarIcon(
            icon: Icons.chat,
            tooltip: 'المحادثات',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatsScreen()),
              ).then((_) => _loadNotificationsCount());
            },
          ),
          _appBarIcon(
            icon: Icons.workspace_premium,
            tooltip: 'إضافة شهادة',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddCertificateSheet(onSaved: _loadData),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(JisrColors.of(context)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _buildBody(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddChildScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة طفل'),
        backgroundColor: AppColors.teal,
      ),
    );
  }

  Widget _appBarIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 18),
      tooltip: tooltip,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildHeader(JisrColors c) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications,
                            color: Colors.white, size: 20),
                        tooltip: 'الإشعارات',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationsScreen()),
                          ).then((_) => _loadNotificationsCount());
                        },
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 15,
                              minHeight: 15,
                            ),
                            child: Text(
                              '$_unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.logout,
                        color: Colors.white, size: 20),
                    tooltip: 'خروج',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () async {
                      await ApiService.logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FutureBuilder<String?>(
                future: ApiService.getName(),
                builder: (context, snap) {
                  final name = snap.data ?? 'ولي الأمر';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً $name 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'أضف أطفالك وتابع تقدمهم التعليمي',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!,
                style: const TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 28),
                label: const Text('إعادة المحاولة',
                    style: TextStyle(fontSize: 18)),
                onPressed: _loadData,
              ),
            ),
          ],
        ),
      );
    }

    if (_children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 72, color: JisrColors.of(context).muted),
            const SizedBox(height: 16),
            Text(
              'لا يوجد أطفال مسجلون بعد',
              style: TextStyle(
                  fontSize: 18, color: JisrColors.of(context).muted),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على زر + لإضافة طفل جديد',
              style: TextStyle(
                  fontSize: 14, color: JisrColors.of(context).muted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _children.length,
      itemBuilder: (context, i) {
        final child = _children[i];
        final name = (child['name'] ?? '').toString();
        final age = child['age'] ?? '?';
        final status = child['status'];
        final color = AppColors.kidPalette[i % AppColors.kidPalette.length];
        final disabilityType = child['disability_type'] ?? 'غير محدد';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              await AccessibilityService.instance.setActiveChild(
                child['id'],
                disabilityTypeHint: child['disability_type']?.toString(),
              );

              if (!context.mounted) return;

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChildDetailsScreen(
                    childId: child['id'],
                    childName: name,
                    childAge: child['age'] is int ? child['age'] as int : 8,
                    parentPhone: child['parent_phone']?.toString(),
                    disabilityType: child['disability_type']?.toString(),
                  ),
                ),
              );

              await AccessibilityService.instance.setActiveChild(null);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color,
                    child: Text(
                      name.isNotEmpty ? name.characters.first : '🙂',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: JisrColors.of(context).heading,
                          ),
                        ),
                        Text(
                          'العمر: $age سنة • $disabilityType',
                          style: TextStyle(
                            fontSize: 14,
                            color: JisrColors.of(context).muted,
                          ),
                        ),
                        if (child['assigned_teacher_name'] != null) ...[
                          Text(
                            'المعلم: ${child['assigned_teacher_name']}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.tealDeep,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditChildScreen(
                                child: child,
                                currentUserRole: 'parent',
                                currentUser: {},
                              ),
                            ),
                          );
                          if (result == true) _loadData();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===== شاشة تفاصيل الطفل =====
class ChildDetailsScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final int childAge;
  final String? parentPhone;
  final String? disabilityType;

  const ChildDetailsScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.childAge,
    this.parentPhone,
    this.disabilityType,
  });

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> {
  Map<String, dynamic>? _childData;
  List _evaluations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.authGet('/children/${widget.childId}'),
        ApiService.authGet('/children/${widget.childId}/evaluations'),
      ]);

      final childData = jsonDecode(results[0].body);
      final evalData = jsonDecode(results[1].body);

      setState(() {
        _childData = childData['child'];
        _evaluations = evalData['evaluations'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذّر تحميل البيانات';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: widget.childName),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person,
                                      color: AppColors.teal),
                                  const SizedBox(width: 8),
                                  Text(
                                    'معلومات الطفل',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: c.heading,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _infoRow('الاسم', _childData?['name'] ?? ''),
                              _infoRow('العمر',
                                  '${_childData?['age'] ?? '?'} سنة'),
                              _infoRow(
                                  'نوع الإعاقة',
                                  _childData?['disability_type'] ??
                                      'غير محدد'),
                              if (_childData?['assigned_teacher_name'] !=
                                  null)
                                _infoRow('المعلم المسؤول',
                                    _childData?['assigned_teacher_name']),
                              _infoRow('الحالة',
                                  _getStatusText(_childData?['status'])),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_evaluations.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.assessment,
                                color: AppColors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'التقييمات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: c.heading,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._evaluations
                            .map((e) => _buildEvaluationCard(e, c)),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.menu_book),
                              label: const Text('الدروس'),
                              onPressed: () async {
                                await AccessibilityService.instance
                                    .setActiveChild(
                                  widget.childId,
                                  disabilityTypeHint: widget.disabilityType,
                                );
                                if (!context.mounted) return;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChildLessonsScreen(
                                      childId: widget.childId,
                                      childName: widget.childName,
                                      age: widget.childAge,
                                      disabilityType: widget.disabilityType,
                                      parentPhone: widget.parentPhone,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.insights),
                              label: const Text('التقدّم'),
                              onPressed: () async {
                                await AccessibilityService.instance
                                    .setActiveChild(widget.childId);
                                if (!context.mounted) return;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChildProgressScreen(
                                      childId: widget.childId,
                                      childName: widget.childName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: JisrColors.of(context).muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: JisrColors.of(context).body,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(Map eval, JisrColors c) {
    final date = eval['created_at'] != null
        ? DateTime.parse(eval['created_at'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment,
                    size: 20, color: AppColors.orange),
                const SizedBox(width: 8),
                Text(
                  eval['evaluation_type'] ?? 'تقييم',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (date != null)
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (eval['recommendations'] != null)
              Text(
                '📝 ${eval['recommendations']}',
                style: const TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'evaluated':
        return 'تم التقييم ✓';
      case 'assigned':
        return 'تم التعيين ✓';
      default:
        return 'قيد الانتظار ⏳';
    }
  }
}