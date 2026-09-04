// شاشة ولي الأمر - إدارة الأطفال ومتابعة تقدمهم
import 'dart:convert';
import 'package:edubridge_app/screens/add_certificate_sheet.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'notifications_screen.dart';
import 'support_sheet.dart';
import 'child_lessons_screen.dart';
import 'child_progress_screen.dart';
import 'add_child_screen.dart';
import 'edit_child_screen.dart';

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
    final c = JisrColors.of(context);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(c),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('assets/icon.png', width: 32, height: 32),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'جسر التعليمي - ولي الأمر',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.headset_mic, color: Colors.white),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const SupportSheet(),
                    ),
                    
                  ),
                  IconButton(
            icon: const Icon(Icons.workspace_premium, color: Colors.white),
            tooltip: 'إضافة شهادة',
            onPressed: () => showModalBottomSheet(
             context: context,
            isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddCertificateSheet(
          onSaved: _loadData,
    ),
  ),
),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          ).then((_) => _loadNotificationsCount());
                        },
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '$_unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'خروج',
                    onPressed: () async {
                      await ApiService.logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                label: const Text('إعادة المحاولة', style: TextStyle(fontSize: 18)),
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
            Icon(Icons.people_outline, size: 72, color: JisrColors.of(context).muted),
            const SizedBox(height: 16),
            Text(
              'لا يوجد أطفال مسجلون بعد',
              style: TextStyle(fontSize: 18, color: JisrColors.of(context).muted),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على زر + لإضافة طفل جديد',
              style: TextStyle(fontSize: 14, color: JisrColors.of(context).muted),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChildDetailsScreen(
                    childId: child['id'],
                    childName: name,
                  ),
                ),
              );
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
                            style: TextStyle(
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.15),
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

  const ChildDetailsScreen({
    super.key,
    required this.childId,
    required this.childName,
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
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
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
                                  const Icon(Icons.person, color: AppColors.teal),
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
                              _infoRow('العمر', '${_childData?['age'] ?? '?'} سنة'),
                              _infoRow('نوع الإعاقة', _childData?['disability_type'] ?? 'غير محدد'),
                              if (_childData?['disability_description'] != null)
                                _infoRow('تفاصيل الإعاقة', _childData?['disability_description']),
                              if (_childData?['special_needs'] != null)
                                _infoRow('احتياجات خاصة', _childData?['special_needs']),
                              if (_childData?['preferred_learning_style'] != null)
                                _infoRow('أسلوب التعلم المفضل', _childData?['preferred_learning_style']),
                              if (_childData?['strengths'] != null)
                                _infoRow('نقاط القوة', (_childData?['strengths'] as List?)?.join(', ') ?? ''),
                              if (_childData?['challenges'] != null)
                                _infoRow('التحديات', (_childData?['challenges'] as List?)?.join(', ') ?? ''),
                              if (_childData?['assigned_teacher_name'] != null)
                                _infoRow('المعلم المسؤول', _childData?['assigned_teacher_name']),
                              _infoRow('الحالة', _getStatusText(_childData?['status'])),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_evaluations.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.assessment, color: AppColors.orange),
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
                        ..._evaluations.map((e) => _buildEvaluationCard(e, c)),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.menu_book),
                              label: const Text('الدروس'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChildLessonsScreen(
                                      childId: widget.childId,
                                      childName: widget.childName,
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
                              onPressed: () {
                                Navigator.push(
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
                const Icon(Icons.assignment, size: 20, color: AppColors.orange),
                const SizedBox(width: 8),
                Text(
                  eval['evaluation_type'] ?? 'تقييم',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
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
            if (eval['educational_plan'] != null)
              Text(
                '📚 الخطة التعليمية: ${eval['educational_plan']}',
                style: TextStyle(fontSize: 14, color: c.muted),
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