// لوحة المختص — متابعة وتقييم الأطفال، تعيين معلمين، متابعة الخطط العلاجية
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/tts_text.dart';
import '../widgets/tts_toggle_button.dart';
import '../widgets/listen_button.dart';
import 'child_progress_screen.dart';
import 'welcome_screen.dart';
import 'chat_screen.dart';
import 'evaluation_sheet.dart';
import 'educational_plan_sheet.dart';

class SpecialistDashboardScreen extends StatefulWidget {
  const SpecialistDashboardScreen({super.key});

  @override
  State<SpecialistDashboardScreen> createState() =>
      _SpecialistDashboardScreenState();
}

class _SpecialistDashboardScreenState extends State<SpecialistDashboardScreen> {
  int _tabIndex = 0;

  List<Map<String, dynamic>> _rows = [];
  List _lessons = [];
  List _types = [];
  List _teachers = [];
  bool _loading = true;
  String? _error;
  int? _approvingId;
  bool _adding = false;
  int _unreadCount = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
    _loadNotificationsCount();
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  bool _isToday(String? ts) {
    if (ts == null || ts.isEmpty) return false;
    final d = DateTime.tryParse(ts.replaceFirst(' ', 'T'));
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Map<String, dynamic> _computeStats(List progress) {
    final total = progress.length;
    final done = progress.where((r) => r['status'] == 'done').length;
    final inProgress =
        progress.where((r) => r['status'] == 'in_progress').length;
    final doneToday = progress
        .where((r) =>
            r['status'] == 'done' && _isToday(r['completed_at']?.toString()))
        .length;
    final pct = total > 0 ? ((done / total) * 100).round() : 0;
    final current = progress.cast<Map?>().firstWhere(
          (r) => r?['status'] == 'in_progress',
          orElse: () => null,
        );
    return {
      'total': total,
      'done': done,
      'inProgress': inProgress,
      'doneToday': doneToday,
      'pct': pct,
      'current': current,
    };
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        ApiService.authGet('/children'),
        ApiService.authGet('/lessons'),
        ApiService.authGet('/disability-types'),
        ApiService.authGet('/users?role=teacher'),
      ]);

      final childrenData = jsonDecode(responses[0].body);
      final lessonsData = jsonDecode(responses[1].body);
      final typesData = jsonDecode(responses[2].body);
      final teachersData = jsonDecode(responses[3].body);

      if (responses[0].statusCode != 200) {
        setState(() {
          _error = childrenData['error'] ?? 'تعذّر جلب البيانات';
          _loading = false;
        });
        return;
      }

      final children = (childrenData['children'] ?? []) as List;
      final rows = <Map<String, dynamic>>[];

      for (final child in children) {
        final pRes =
            await ApiService.authGet('/progress/child/${child['id']}');
        final pData = jsonDecode(pRes.body);
        final progress =
            pRes.statusCode == 200 ? (pData['progress'] ?? []) : [];
        rows.add({
          'child': child,
          'progress': progress,
          'stats': _computeStats(progress),
        });
      }

      setState(() {
        _rows = rows;
        _lessons = lessonsData['lessons'] ?? [];
        _types = typesData['disability_types'] ?? [];
        _teachers = teachersData['users'] ?? [];
        _loading = false;
      });
    } catch (_) {
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

  Future<void> _approve(Map<String, dynamic> row) async {
    final current = row['stats']['current'];
    if (current == null) return;

    final childId = row['child']['id'];
    setState(() => _approvingId = childId);

    try {
      final res = await ApiService.authPost('/progress', {
        'child_id': childId,
        'lesson_id': current['lesson_id'],
        'status': 'done',
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم اعتماد إنجاز الدرس'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final data = jsonDecode(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'فشل الاعتماد')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الاتصال بالسيرفر')),
        );
      }
    } finally {
      if (mounted) setState(() => _approvingId = null);
    }
  }

  void _openEvaluation(Map<String, dynamic> row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EvaluationSheet(
        child: row['child'],
        teachers: _teachers,
        onSaved: (updatedChild) {
          setState(() {
            final index = _rows.indexWhere((r) => r['child']['id'] == updatedChild['id']);
            if (index != -1) {
              _rows[index]['child'] = updatedChild;
            }
          });
          _load();
        },
      ),
    );
  }

  void _viewEvaluation(int childId) {
    // عرض آخر تقييم للطفل
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FutureBuilder(
        future: ApiService.getChildEvaluations(childId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: JisrColors.of(context).card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assessment, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'لا يوجد تقييم مسجل',
                    style: TextStyle(color: JisrColors.of(context).muted),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            );
          }
          final evaluation = snapshot.data!.last;
          return _buildEvaluationViewModal(evaluation);
        },
      ),
    );
  }

  Widget _buildEvaluationViewModal(Map evaluation) {
    final c = JisrColors.of(context);
    final date = evaluation['created_at'] != null
        ? DateTime.parse(evaluation['created_at'])
        : null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assessment, color: AppColors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تفاصيل التقييم',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (date != null)
              Text(
                'التاريخ: ${date.day}/${date.month}/${date.year}',
                style: TextStyle(color: c.muted),
              ),
            const SizedBox(height: 12),
            _detailRow('🧠 التقييم المعرفي', evaluation['cognitive_assessment']),
            _detailRow('🏃 التقييم الحركي', evaluation['motor_assessment']),
            _detailRow('💚 التقييم العاطفي', evaluation['emotional_assessment']),
            _detailRow('🤝 التقييم الاجتماعي', evaluation['social_assessment']),
            _detailRow('📝 التوصيات', evaluation['recommendations']),
            _detailRow('📚 الخطة التعليمية', evaluation['educational_plan']),
            if (evaluation['teaching_methods'] != null) ...[
              const SizedBox(height: 8),
              const Text(
                'طرق التدريس المقترحة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (evaluation['teaching_methods'] as List? ?? [])
                    .map((method) => Chip(
                          label: Text(method),
                          backgroundColor: c.tintGreen,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    ).then((_) => _loadNotificationsCount());
  }

  List get _pendingChildren {
    return _rows.where((row) {
      final status = row['child']['status'] ?? '';
      return status != 'evaluated' && status != 'assigned';
    }).toList();
  }

  List get _filteredChildren {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _rows;
    return _rows.where((row) {
      final name = (row['child']['name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  int get _totalChildren => _rows.length;
  int get _pendingCount => _pendingChildren.length;
  int get _doneToday =>
      _rows.fold(0, (s, r) => s + (r['stats']['doneToday'] as int));
  int get _pendingProgress =>
      _rows.fold(0, (s, r) => s + (r['stats']['inProgress'] as int));

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(c),
              // شريط التبويب المخصص
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // حقل البحث للأطفال
                    if (_tabIndex == 0)
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: '🔍 ابحث عن طفل...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                    const Spacer(),
                    // زر الإشعارات
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: _openNotifications,
                          tooltip: 'الإشعارات',
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
                                minWidth: 16,
                                minHeight: 16,
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
                  ],
                ),
              ),
              // بطاقات الإحصائيات
              if (_tabIndex == 0 && !_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _StatsCard(
                        icon: '⏳',
                        value: '$_pendingCount',
                        label: 'بانتظار التقييم',
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 8),
                      _StatsCard(
                        icon: '✅',
                        value: '$_doneToday',
                        label: 'منجز اليوم',
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 8),
                      _StatsCard(
                        icon: '📊',
                        value: '$_pendingProgress',
                        label: 'قيد التنفيذ',
                        color: AppColors.teal,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _buildError()
                          : _tabIndex == 0
                              ? _buildProgressTab(c)
                              : _buildLessonsTab(c),
                ),
              ),
            ],
          ),
          if (_adding) _buildAddModal(c),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'التقدّم',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'الدروس',
          ),
        ],
      ),
      floatingActionButton: _tabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _adding = true),
              icon: const Icon(Icons.add),
              label: const Text('إضافة درس'),
              backgroundColor: AppColors.green,
            )
          : null,
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
                      'جسر التعليمي - المختص',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const ListenButton(color: Colors.white),
                   TtsToggleButton(),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'خروج',
                    onPressed: _logout,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<String?>(
                future: ApiService.getName(),
                builder: (context, snap) {
                  final name = snap.data ?? 'المختص';
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
                        _tabIndex == 0
                            ? 'إليك نظرة عامة على تقدّم الأطفال والخطط العلاجية'
                            : 'أضف دروساً جديدة أو صفّح الدروس الموجودة',
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

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
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
                  onPressed: _load,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTab(JisrColors c) {
    final displayChildren = _filteredChildren;

    if (displayChildren.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.people_outline, size: 72, color: c.muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _rows.isEmpty ? 'لا يوجد أطفال مسجلون بعد' : 'لا نتائج مطابقة للبحث',
              style: TextStyle(fontSize: 18, color: c.muted),
            ),
          ),
          if (_rows.isEmpty)
            const SizedBox(height: 8),
          if (_rows.isEmpty)
            Center(
              child: Text(
                'سيظهر الأطفال هنا بعد أن يضيفهم أولياء الأمور',
                style: TextStyle(fontSize: 14, color: c.muted),
              ),
            ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: displayChildren.length,
      itemBuilder: (context, i) =>
          _buildProgressRow(displayChildren[i] as Map<String, dynamic>, c),
    );
  }

  Widget _buildProgressRow(Map<String, dynamic> row, JisrColors c) {
    final child = row['child'];
    final stats = row['stats'] as Map<String, dynamic>;
    final current = stats['current'];
    final name = (child['name'] ?? '').toString();
    final need = (child['disability_type'] ?? '').toString();
    final childId = child['id'];
    final approving = _approvingId == childId;
    final status = child['status'] ?? 'pending';
    final isPending = status == 'pending' || status == '';
    final color = AppColors.kidPalette[
        _rows.indexOf(row) % AppColors.kidPalette.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color,
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '🧒',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChildProgressScreen(
                            childId: childId,
                            childName: name,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          ),
                        ),
                        if (need.isNotEmpty)
                          Text(
                            'الإعاقة: $need',
                            style: TextStyle(fontSize: 13, color: c.muted),
                          ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${stats['pct']}% ⭐',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                      ),
                    ),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'بانتظار التقييم',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orangeDeep,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (current != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.tintOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🕒 ${current['lesson_title'] ?? ''}',
                      style: TextStyle(fontSize: 13, color: c.onTint),
                    ),
                  ),
                if ((stats['inProgress'] as int) > 0)
                  _CountBadge(
                    '${stats['inProgress']} قيد التنفيذ',
                    color: AppColors.orange,
                  ),
                if ((stats['done'] as int) > 0)
                  _CountBadge(
                    '${stats['done']} ✅ مكتمل',
                    color: AppColors.green,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: isPending
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                          ),
                          icon: const Icon(Icons.assessment, color: Colors.white),
                          label: const Text('تقييم الطفل'),
                          onPressed: () => _openEvaluation(row),
                        )
                      : OutlinedButton.icon(
                          icon: const Icon(Icons.visibility),
                          label: const Text('عرض التقييم'),
                          onPressed: () => _viewEvaluation(childId),
                        ),
                ),
                if (!isPending && child['assigned_teacher_id'] == null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('تعيين معلم'),
                      onPressed: () => _openAssignTeacher(row),
                    ),
                  ),
                ],
                if (current != null && !isPending) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                      ),
                      icon: approving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        approving ? 'جارٍ...' : 'اعتماد',
                        style: const TextStyle(fontSize: 14),
                      ),
                      onPressed: approving ? null : () => _approve(row),
                    ),
                  ),
                ],
              ],
            ),
            if (child['assigned_teacher_name'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: c.tintTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.tealDeep),
                    const SizedBox(width: 6),
                    Text(
                      'المعلم: ${child['assigned_teacher_name']}',
                      style: TextStyle(fontSize: 13, color: c.onTint),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => _openChatWithTeacher(child),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'تواصل',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openAssignTeacher(Map<String, dynamic> row) {
    final child = row['child'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignTeacherSheet(
        child: child,
        teachers: _teachers,
        onAssigned: (updatedChild) {
          setState(() {
            final index = _rows.indexWhere((r) => r['child']['id'] == updatedChild['id']);
            if (index != -1) {
              _rows[index]['child'] = updatedChild;
            }
          });
          _load();
        },
      ),
    );
  }

  void _openChatWithTeacher(Map child) async {
    try {
      final teacherId = child['assigned_teacher_id'];
      final teacherName = child['assigned_teacher_name'] ?? 'المعلم';
      
      final conversationId = await ApiService.createConversation(
        teacherId,
        'مناقشة حالة ${child['name']}',
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherUserName: teacherName,
            otherUserRole: 'معلم',
            childName: child['name'] ?? '',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر إنشاء المحادثة: $e')),
      );
    }
  }

  Widget _buildLessonsTab(JisrColors c) {
    if (_lessons.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.menu_book, size: 72, color: c.muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'لا توجد دروس بعد',
              style: TextStyle(fontSize: 18, color: c.muted),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'أضف درساً جديداً باستخدام زر +',
              style: TextStyle(fontSize: 14, color: c.muted),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _lessons.length,
      itemBuilder: (context, i) =>
          _buildLessonCard(_lessons[i], c),
    );
  }

  Widget _buildLessonCard(Map lesson, JisrColors c) {
    final title = (lesson['title'] ?? '').toString();
    final tag = _typeName(lesson['disability_type_id']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: c.tintGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.menu_book, size: 28, color: c.success),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.heading,
          ),
        ),
        subtitle: tag != null
            ? Text(tag, style: const TextStyle(fontSize: 13))
            : null,
        trailing: const Icon(Icons.chevron_left),
        onTap: () => _viewLessonDetail(lesson),
      ),
    );
  }

  void _viewLessonDetail(Map lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LessonDetailSheet(lesson: lesson),
    );
  }

  String? _typeName(int? id) {
    if (id == null) return null;
    for (final t in _types) {
      if (t['id'] == id) return (t['name'] ?? '').toString();
    }
    return null;
  }

  Widget _buildAddModal(JisrColors c) {
    return Positioned.fill(
      child: _AddLessonSheet(
        types: _types,
        onClose: () => setState(() => _adding = false),
        onCreated: (lesson) {
          setState(() {
            _lessons = [lesson, ..._lessons];
            _adding = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة الدرس بنجاح 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}

// ===== مكوّنات مساعدة =====

class _StatsCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const _StatsCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.line),
        ),
        child: Column(
          children: [
            Text(
              '$icon $value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: c.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _CountBadge(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ===== شاشة تعيين معلم =====
class _AssignTeacherSheet extends StatefulWidget {
  final Map child;
  final List teachers;
  final void Function(Map) onAssigned;

  const _AssignTeacherSheet({
    required this.child,
    required this.teachers,
    required this.onAssigned,
  });

  @override
  State<_AssignTeacherSheet> createState() => _AssignTeacherSheetState();
}

class _AssignTeacherSheetState extends State<_AssignTeacherSheet> {
  int? _selectedTeacherId;
  bool _loading = false;
  String? _error;

  Future<void> _assign() async {
    if (_selectedTeacherId == null) {
      setState(() => _error = 'يرجى اختيار معلم');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.assignTeacherToChild(
        widget.child['id'],
        _selectedTeacherId!,
      );

      if (result != null) {
        widget.onAssigned(result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تعيين المعلم بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تعيين معلم - ${widget.child['name'] ?? ''}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.teachers.isEmpty)
            Center(
              child: Text(
                'لا يوجد معلمون مسجلون حالياً',
                style: TextStyle(color: c.muted),
              ),
            )
          else
            Column(
              children: [
                ...widget.teachers.map((teacher) => RadioListTile<int>(
                      title: Text(teacher['name'] ?? 'معلم'),
                      subtitle: Text(teacher['email'] ?? ''),
                      value: teacher['id'],
                      groupValue: _selectedTeacherId,
                      onChanged: (val) => setState(() => _selectedTeacherId = val),
                    )),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                        ),
                        onPressed: _loading ? null : _assign,
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('تعيين'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ===== شاشة تفاصيل الدرس =====
class _LessonDetailSheet extends StatelessWidget {
  final Map lesson;

  const _LessonDetailSheet({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final title = (lesson['title'] ?? '').toString();
    final content = (lesson['content'] ?? '').toString();
    final videoUrl = lesson['video_url'];
    final audioUrl = lesson['audio_url'];
    final createdAt = lesson['created_at'] != null
        ? DateTime.parse(lesson['created_at'])
        : null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (createdAt != null)
              Text(
                'تاريخ الإضافة: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            const SizedBox(height: 12),
            if (content.isNotEmpty)
              Text(
                content,
                style: TextStyle(fontSize: 16, height: 1.5, color: c.body),
              ),
            if (videoUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.tintTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.video_library, color: AppColors.tealDeep),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('📹 فيديو مرفق'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow, size: 28),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('سيتم تشغيل الفيديو قريباً'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            if (audioUrl != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.tintGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.audio_file, color: AppColors.greenDeep),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('🎵 تسجيل صوتي مرفق'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow, size: 28),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('سيتم تشغيل التسجيل قريباً'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.volume_up),
                label: const Text('استمع للدرس'),
                onPressed: () async {
                  final text = [
                    title,
                    content,
                  ].where((t) => t.isNotEmpty).join('. ');
                  await TtsService.instance.speakLine(text);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== شاشة الإشعارات (مستقلة) =====
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
          TextButton(
            onPressed: () async {
              await ApiService.markAllNotificationsRead();
              _loadNotifications();
            },
            child: const Text('تحديد الكل كمقروء'),
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

                        return Card(
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
                        );
                      },
                    ),
    );
  }
}

// ===== مكوّن إضافة الدرس =====
class _AddLessonSheet extends StatefulWidget {
  final List types;
  final VoidCallback onClose;
  final void Function(Map lesson) onCreated;

  const _AddLessonSheet({
    required this.types,
    required this.onClose,
    required this.onCreated,
  });

  @override
  State<_AddLessonSheet> createState() => _AddLessonSheetState();
}

class _AddLessonSheetState extends State<_AddLessonSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String? _typeId;
  File? _videoFile;
  File? _audioFile;
  bool _saving = false;
  String? _error;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _videoFile = File(video.path));
    }
  }

  Future<void> _pickAudio() async {
    final XFile? audio = await _picker.pickMedia();
    if (audio != null) {
      setState(() => _audioFile = File(audio.path));
    }
  }

  void _removeVideo() {
    setState(() => _videoFile = null);
  }

  void _removeAudio() {
    setState(() => _audioFile = null);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'عنوان الدرس مطلوب');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result = await ApiService.createLessonWithMedia(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
        disabilityTypeId: _typeId != null ? int.parse(_typeId!) : null,
        videoFile: _videoFile,
        audioFile: _audioFile,
      );

      if (!mounted) return;

      if (result != null) {
        widget.onCreated(result);
      } else {
        setState(() {
          _error = 'فشل حفظ الدرس';
          _saving = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر: $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '➕ إضافة درس جديد',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الدرس *',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'المحتوى النصي',
                      hintText: 'اكتب محتوى الدرس (اختياري)...',
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'نوع الإعاقة المستهدَف',
                      prefixIcon: Icon(Icons.medical_services),
                    ),
                    value: _typeId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('— عام (كل الأنواع) —'),
                      ),
                      ...widget.types.map((t) => DropdownMenuItem(
                            value: t['id'].toString(),
                            child: Text((t['name'] ?? '').toString()),
                          )),
                    ],
                    onChanged: (v) => setState(() => _typeId = v),
                  ),
                  const SizedBox(height: 16),

                  // رفع الفيديو
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.tintTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎬 فيديو الدرس (اختياري)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: c.onTint,
                          ),
                        ),
                        if (_videoFile == null) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.upload_file, size: 18),
                              label: const Text('اختر ملف فيديو'),
                              onPressed: _pickVideo,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: c.success),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _videoFile!.path.split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.onTint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: c.onTint, size: 18),
                                onPressed: _removeVideo,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // رفع الصوت
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.tintGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎙️ تسجيل صوتي (اختياري)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: c.onTint,
                          ),
                        ),
                        if (_audioFile == null) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.upload_file, size: 18),
                              label: const Text('اختر ملف صوت'),
                              onPressed: _pickAudio,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: c.success),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _audioFile!.path.split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.onTint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: c.onTint, size: 18),
                                onPressed: _removeAudio,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onClose,
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                          ),
                          onPressed: _saving ? null : _save,
                          child: Text(
                            _saving ? 'جارِ الحفظ...' : 'حفظ الدرس',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================== مكوّنات مساعدة ==================
class _SummaryCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            TtsText(
              '$icon $value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            TtsText(
              label,
              style: TextStyle(fontSize: 11, color: c.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
