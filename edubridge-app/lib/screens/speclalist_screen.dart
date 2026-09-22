// شاشة المختص — كاملة مع:
// - Switch "أطفالي / قائمة الانتظار"
// - استخراج التخصص تلقائياً من /me
// - فتح شاشة تحديد التخصص عند عدم وجوده
// - اقتراح مختص دعم تعليمي
// - دراسة الحالة
import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../services/api_service.dart';
import '../services/notification_listener_service.dart';
import '../theme.dart';
import '../widgets/accessibility/profile_avatar_button.dart';
import '../widgets/legal_links_button.dart';
import '../widgets/dashboard_menu.dart';
import '../utils/navigation.dart';
import 'add_certificate_sheet.dart';
import 'add_lesson_sheet.dart';
import 'case_discussion_screen.dart';
import 'choose_specialty_screen.dart';
import 'plan_evaluation_screen.dart';
import 'learning_support_requests_screen.dart';
import 'learning_support_meetings_screen.dart';
import 'specialist_suggestions_screen.dart';
import 'welcome_screen.dart';
import 'evaluation_sheet.dart';
import 'support_sheet.dart';
import 'child_progress_screen.dart';
import 'chats_screen.dart';
import 'verify_identity_screen.dart';
import 'notifications_screen.dart';
import 'weekly_report_screen.dart';
import 'create_specialist_progress_screen.dart';

class SpecialistDashboardScreen extends StatefulWidget {
  const SpecialistDashboardScreen({super.key});

  @override
  State<SpecialistDashboardScreen> createState() =>
      _SpecialistDashboardScreenState();
}

class _SpecialistDashboardScreenState
    extends State<SpecialistDashboardScreen> {
  int _tabIndex = 0;

  List<Map<String, dynamic>> _rows = [];
  List _lessons = [];
  List _types = [];
  List _teachers = [];
  List _specialists = [];
  bool _loading = true;
  String? _error;
  int? _approvingId;
  bool _adding = false;
  String _searchQuery = '';

  // ✅ Switch: أطفالي فقط / قائمة الانتظار
  bool _showOnlyMine = true;
  int? _currentUserId;
  String? _mySpecialty; // 'learning_support' | 'educational' | null

  bool _verificationDialogShown = false;
  bool _specialtyDialogShown = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    _currentUserId = await ApiService.getUserId();
    await _load();
    await _checkSpecialty();
    _checkAndShowVerificationDialog();
  }

  @override
  void dispose() {
    if (_adding) inlineModalOpen.value = false;
    super.dispose();
  }

  void _setAdding(bool value) {
    inlineModalOpen.value = value;
    setState(() => _adding = value);
  }

  // ═══════════════════════════════════════════════════════════
  //  التحقق من التخصص — يفتح شاشة الاختيار لو غير محدد
  // ═══════════════════════════════════════════════════════════
  Future<void> _checkSpecialty() async {
    if (_specialtyDialogShown) return;
    if (_mySpecialty != null) return;
    if (!mounted) return;

    _specialtyDialogShown = true;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ChooseSpecialtyScreen(),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      setState(() => _mySpecialty = result);
      await _load(); // أعد التحميل ليعكس التخصص الجديد
    } else {
      _specialtyDialogShown = false; // اسمح بإعادة المحاولة
    }
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
        ApiService.authGet('/users?role=specialist'),
      ]);

      final childrenData = jsonDecode(responses[0].body);
      final lessonsData = jsonDecode(responses[1].body);
      final typesData = jsonDecode(responses[2].body);
      final teachersData = jsonDecode(responses[3].body);
      final specialistsData = jsonDecode(responses[4].body);

      if (responses[0].statusCode != 200) {
        if (!mounted) return;
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

      // ═══════════════════════════════════════════════════════
      //  ✅ استخراج التخصص (3 طرق متتالية)
      // ═══════════════════════════════════════════════════════
      String? specialty;

      // 1) من /me (الأدق)
      try {
        final meRes = await ApiService.authGet('/me');
        if (meRes.statusCode == 200) {
          final meData = jsonDecode(meRes.body);
          final me = meData['user'] ?? meData;
          final spec =
              (me['specialty'] ?? '').toString().toLowerCase().trim();
          if (spec.isNotEmpty) {
            if (spec == 'learning_support' || spec.contains('نفس')) {
              specialty = 'learning_support';
            } else if (spec == 'educational' || spec.contains('تعليم')) {
              specialty = 'educational';
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ فشل /me: $e');
      }

      // 2) من قائمة المختصين
      if (specialty == null) {
        final meUser = (specialistsData['users'] as List? ?? []).firstWhere(
          (u) => u['id'] == _currentUserId,
          orElse: () => <String, dynamic>{},
        );
        final spec =
            (meUser['specialty'] ?? '').toString().toLowerCase().trim();
        if (spec == 'learning_support' || spec.contains('نفس')) {
          specialty = 'learning_support';
        } else if (spec == 'educational' || spec.contains('تعليم')) {
          specialty = 'educational';
        }
      }

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _lessons = lessonsData['lessons'] ?? [];
        _types = typesData['disability_types'] ?? [];
        _teachers = teachersData['users'] ?? [];
        _specialists = specialistsData['users'] ?? [];
        _mySpecialty = specialty;
        _loading = false;
      });

      debugPrint(
          '🔍 _currentUserId=$_currentUserId, _mySpecialty=$_mySpecialty');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  Future<void> _checkAndShowVerificationDialog() async {
    if (_verificationDialogShown) return;
    final isVerified = await ApiService.isVerified();
    if (isVerified) return;
    if (!mounted) return;
    _verificationDialogShown = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user,
                    size: 48, color: AppColors.orange),
              ),
              const SizedBox(height: 20),
              Text(
                'توثيق الهوية مطلوب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: JisrColors.of(context).heading,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'عزيزي المختص، يجب توثيق هويتك ورفع شهادتك العلمية للاستفادة من كامل صلاحيات التطبيق.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: JisrColors.of(context).muted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.verified_user, size: 22),
                  label: const Text(
                    'توثيق الهوية والشهادة',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VerifyIdentityScreen(),
                      ),
                    );
                    if (!mounted) return;
                    final nowVerified = await ApiService.isVerified();
                    if (!mounted) return;
                    if (nowVerified) {
                      setState(() {});
                    } else {
                      _verificationDialogShown = false;
                      _checkAndShowVerificationDialog();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _checkVerification() async {
    if (!await ApiService.isVerified()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ يرجى توثيق الهوية أولاً'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _approve(Map<String, dynamic> row) async {
    if (!await _checkVerification()) return;
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم اعتماد إنجاز الدرس'),
            backgroundColor: Colors.green,
          ),
        );
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

  void _openEvaluation(Map<String, dynamic> row) async {
    if (!await _checkVerification()) return;
    final child = row['child'];
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EvaluationSheet(
        child: child,
        teachers: _teachers,
        onSaved: (updatedChild) {
          setState(() {
            final index = _rows.indexWhere(
                (r) => r['child']['id'] == updatedChild['id']);
            if (index != -1) {
              _rows[index]['child'] = updatedChild;
            }
          });
          _load();
        },
      ),
    );
  }

  Future<void> _viewEvaluation(int childId) async {
    final row = _rows.firstWhere(
      (r) => r['child']['id'] == childId,
      orElse: () => {},
    );
    final child = row['child'] as Map?;
    if (!mounted) return;

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
          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
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
                  Text('لا يوجد تقييم مسجل',
                      style: TextStyle(color: JisrColors.of(context).muted)),
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
                  child: Text('تفاصيل التقييم',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      )),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (date != null)
              Text('التاريخ: ${date.day}/${date.month}/${date.year}',
                  style: TextStyle(color: c.muted)),
            const SizedBox(height: 12),
            _detailRow('🧠 التقييم المعرفي', evaluation['cognitive_assessment']),
            _detailRow('🏃 التقييم الحركي', evaluation['motor_assessment']),
            _detailRow('💚 التقييم العاطفي', evaluation['emotional_assessment']),
            _detailRow('🤝 التقييم الاجتماعي', evaluation['social_assessment']),
            _detailRow('📝 التوصيات', evaluation['recommendations']),
            _detailRow('📚 الخطة التعليمية', evaluation['educational_plan']),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  void _openLearningSupport() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const LearningSupportMeetingsScreen()));
  }

  void _openCaseDiscussion({int? childId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseDiscussionScreen(filterChildId: childId),
      ),
    );
  }

  void _openSuggestions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SpecialistSuggestionsScreen(),
      ),
    );
  }

  void _openPlanEvaluation(Map<String, dynamic> row) {
    final child = row['child'];
    final planId = child['current_plan_id'] ?? 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanEvaluationScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
          planId: planId is int ? planId : 0,
        ),
      ),
    );
  }

  Future<void> _openTeacherReport(Map<String, dynamic> row) async {
    final child = row['child'];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeeklyReportScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
        ),
      ),
    );
  }

  Future<void> _writeProgressBasedOnReport(
      Map<String, dynamic> row) async {
    if (!await _checkVerification()) return;
    if (!mounted) return;
    final child = row['child'];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSpecialistProgressScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _recommendLearningSupport(Map<String, dynamic> row) async {
    if (!await _checkVerification()) return;
    if (!mounted) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecommendLearningSupportSheet(child: row['child']),
    );
    if (result == true) _load();
  }

  // ═══════════════════════════════════════════════════════════
  //  منطق الفلترة
  // ═══════════════════════════════════════════════════════════

  Set<int> _childSpecialistIds(Map<String, dynamic> child) {
    final ids = <int>{};
    final single = child['specialist_id'];
    if (single is int) ids.add(single);
    if (single is String) {
      final v = int.tryParse(single);
      if (v != null) ids.add(v);
    }
    for (final key in [
      'specialist_ids',
      'assigned_specialist_ids',
      'specialists'
    ]) {
      final list = child[key];
      if (list is List) {
        for (final item in list) {
          if (item is int) ids.add(item);
          if (item is String) {
            final v = int.tryParse(item);
            if (v != null) ids.add(v);
          }
          if (item is Map && item['id'] != null) {
            final v = item['id'] is int
                ? item['id'] as int
                : int.tryParse(item['id'].toString());
            if (v != null) ids.add(v);
          }
        }
      }
    }
    return ids;
  }

  bool _isMyChild(Map<String, dynamic> child) {
    if (_currentUserId == null) return false;
    return _childSpecialistIds(child).contains(_currentUserId);
  }

  bool _hasBothSpecialists(Map<String, dynamic> child) {
    final specIds = _childSpecialistIds(child);
    if (specIds.length < 2) return false;

    int psychCount = 0;
    int eduCount = 0;
    int unknownCount = 0;

    for (final id in specIds) {
      final s = _specialists.firstWhere(
        (u) => u['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      final spec = (s['specialty'] ?? '').toString().toLowerCase();
      if (spec == 'learning_support' || spec.contains('نفس')) {
        psychCount++;
      } else if (spec == 'educational' || spec.contains('تعليم')) {
        eduCount++;
      } else {
        unknownCount++;
      }
    }
    if (psychCount >= 1 && eduCount >= 1) return true;
    if (psychCount + eduCount == 0 && unknownCount >= 2) return true;
    return false;
  }

  bool _hasSpecialistOfType(Map<String, dynamic> child, String type) {
    final specIds = _childSpecialistIds(child);
    for (final id in specIds) {
      final s = _specialists.firstWhere(
        (u) => u['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      final spec = (s['specialty'] ?? '').toString().toLowerCase();
      if (spec == type) return true;
      if (type == 'learning_support' && spec.contains('نفس')) return true;
      if (type == 'educational' && spec.contains('تعليم')) return true;
    }
    return false;
  }

  bool _isInWaitingList(Map<String, dynamic> child) {
    if (_isMyChild(child)) return false;
    if (_hasBothSpecialists(child)) return false;
    if (_mySpecialty == null || _mySpecialty!.isEmpty) {
      return _childSpecialistIds(child).isEmpty;
    }
    if (_mySpecialty == 'learning_support') {
      return !_hasSpecialistOfType(child, 'learning_support');
    }
    if (_mySpecialty == 'educational') {
      return !_hasSpecialistOfType(child, 'educational');
    }
    return false;
  }

  List get _filteredChildren {
    final query = _searchQuery.trim().toLowerCase();
    List<Map<String, dynamic>> base;
    if (_showOnlyMine) {
      base = _rows.where((r) => _isMyChild(r['child'])).toList();
    } else {
      base = _rows.where((r) => _isInWaitingList(r['child'])).toList();
    }
    if (query.isEmpty) return base;
    return base.where((row) {
      final name = (row['child']['name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  List get _pendingChildren => _rows.where((row) {
        final s = row['child']['status'] ?? '';
        return s != 'evaluated' && s != 'assigned';
      }).toList();

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
              // ─── البحث + الجرس ───
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (_tabIndex == 0)
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: '🔍 ابحث عن طفل...',
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onChanged: (v) =>
                              setState(() => _searchQuery = v),
                        ),
                      )
                    else
                      const Spacer(),
                    ValueListenableBuilder<int>(
                      valueListenable:
                          NotificationListenerService.instance.unreadCount,
                      builder: (context, count, _) {
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined),
                              onPressed: _openNotifications,
                              tooltip: 'الإشعارات',
                            ),
                            if (count > 0)
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
                                      minWidth: 16, minHeight: 16),
                                  child: Text('$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              // ─── Switch + الإحصائيات ───
              if (_tabIndex == 0 && !_loading) ...[
                _buildFilterCard(c),
                const SizedBox(height: 8),
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
              ],
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _buildError()
                          : _buildBody(c),
                ),
              ),
            ],
          ),
          if (_adding) _buildAddModal(c),
        ],
      ),
      bottomNavigationBar: _adding
          ? null
          : NavigationBar(
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
      floatingActionButton: _tabIndex == 1 && !_adding
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (await _checkVerification()) _setAdding(true);
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة درس'),
              backgroundColor: AppColors.green,
            )
          : null,
    );
  }

  // ─── بطاقة الفلترة (Switch) ───
  Widget _buildFilterCard(JisrColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _showOnlyMine
              ? AppColors.tealDeep.withValues(alpha: 0.1)
              : AppColors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _showOnlyMine ? AppColors.tealDeep : AppColors.orangeDeep,
            width: 1.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _showOnlyMine
                    ? AppColors.tealDeep
                    : AppColors.orangeDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                _showOnlyMine ? Icons.person : Icons.hourglass_top,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        _showOnlyMine ? 'أطفالي فقط' : 'قائمة الانتظار',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _showOnlyMine
                              ? AppColors.tealDeep
                              : AppColors.orangeDeep,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _showOnlyMine
                              ? AppColors.tealDeep
                              : AppColors.orangeDeep,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_filteredChildren.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _showOnlyMine
                        ? 'الأطفال المعيّنون لك'
                        : 'أطفال يحتاجون مختص',
                    style: TextStyle(fontSize: 11, color: c.muted),
                  ),
                ],
              ),
            ),
            Switch(
              value: _showOnlyMine,
              activeThumbColor: AppColors.tealDeep,
              inactiveThumbColor: AppColors.orangeDeep,
              inactiveTrackColor:
                  AppColors.orange.withValues(alpha: 0.35),
              onChanged: (v) => setState(() => _showOnlyMine = v),
            ),
          ],
        ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ProfileAvatarButton(size: 42),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/brand_icon.png',
                          width: 40, height: 40),
                      const SizedBox(width: 6),
                      const Text('EduBridge',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                    ],
                  ),
                  DashboardMenu(
                    actions: [
                      DashboardMenuAction(
                        id: 'case_discussion',
                        label: 'دراسات الحالة',
                        icon: Icons.forum,
                        onSelected: () => _openCaseDiscussion(),
                      ),
                      DashboardMenuAction(
                        id: 'suggestions',
                        label: 'اقتراحات المتابعة',
                        icon: Icons.handshake,
                        onSelected: _openSuggestions,
                      ),
                      DashboardMenuAction(
                        id: 'learning_support_requests',
                        label: 'طلبات الدعم التعليمي',
                        icon: Icons.psychology_alt,
                        onSelected: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LearningSupportRequestsScreen(),
                          ),
                        ),
                      ),
                      DashboardMenuAction(
                        id: 'learning_support',
                        label: 'الجلسات المجدولة',
                        icon: Icons.event_available,
                        onSelected: _openLearningSupport,
                      ),
                      DashboardMenuAction(
                        id: 'support',
                        label: 'الدعم الفني',
                        icon: Icons.headset_mic,
                        onSelected: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const SupportSheet(),
                        ),
                      ),
                      DashboardMenuAction(
                        id: 'certificate',
                        label: 'إضافة شهادة',
                        icon: Icons.workspace_premium_outlined,
                        onSelected: () async {
                          if (await _checkVerification()) {
                            if (!mounted) return;
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) =>
                                  AddCertificateSheet(onSaved: _load),
                            );
                          }
                        },
                      ),
                      DashboardMenuAction(
                        id: 'chats',
                        label: 'المحادثات',
                        icon: Icons.chat_outlined,
                        onSelected: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChatsScreen()),
                        ),
                      ),
                      DashboardMenuAction(
                        id: 'legal',
                        label: 'الخصوصية والحساب',
                        icon: Icons.privacy_tip_outlined,
                        onSelected: () =>
                            const LegalLinksButton().show(context),
                      ),
                      DashboardMenuAction(
                        id: 'logout',
                        label: 'تسجيل الخروج',
                        icon: Icons.logout,
                        destructive: true,
                        onSelected: _logout,
                      ),
                    ],
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
                      Text('مرحباً $name 👋',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                      Text(
                        _tabIndex == 0
                            ? 'نظرة عامة على الأطفال'
                            : 'أضف دروساً لأولياء الأمور وللأطفال',
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

  Widget _buildBody(JisrColors c) {
    return _tabIndex == 0 ? _buildProgressTab(c) : _buildLessonsTab(c);
  }

  Widget _buildProgressTab(JisrColors c) {
    final displayChildren = _filteredChildren;

    if (displayChildren.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(
            _showOnlyMine ? Icons.person_off : Icons.hourglass_empty,
            size: 72,
            color: c.muted,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _showOnlyMine
                  ? 'لا يوجد أطفال معيّنون لك حالياً'
                  : 'لا يوجد أطفال في قائمة الانتظار',
              style: TextStyle(fontSize: 18, color: c.muted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: displayChildren.length,
      itemBuilder: (context, i) => _buildProgressRow(
          displayChildren[i] as Map<String, dynamic>, c),
    );
  }

  Widget _buildProgressRow(Map<String, dynamic> row, JisrColors c) {
    if (!_showOnlyMine) return _buildAvailableChildCard(row, c);
    return _buildMyChildCard(row, c);
  }

  // ═══════════════════════════════════════════════════════════
  //  بطاقة الطفل المتاح (قائمة الانتظار)
  // ═══════════════════════════════════════════════════════════
  Widget _buildAvailableChildCard(
      Map<String, dynamic> row, JisrColors c) {
    final child = row['child'];
    final name = (child['name'] ?? '').toString();
    final age = child['age'] ?? '?';
    final disability = (child['disability_type'] ?? '').toString();
    final description = (child['disability_description'] ?? '').toString();
    final medicalHistory = (child['medical_history'] ?? '').toString();
    final strengths = (child['strengths'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final challenges = (child['challenges'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final preferredStyle =
        (child['preferred_learning_style'] ?? '').toString();
    final specialNeeds = (child['special_needs'] ?? '').toString();

    final color = AppColors
        .kidPalette[_rows.indexOf(row) % AppColors.kidPalette.length];
    final isAdding = _approvingId == child['id'];
    final hasSpecialty = _mySpecialty != null;

    // ✅ احسب التسمية والألوان حسب التخصص
    final specType = _mySpecialty == 'learning_support'
        ? 'مختص دعم تعليمي'
        : _mySpecialty == 'educational'
            ? 'مختص تعليمي'
            : 'مختص (تخصصك غير محدد)';

    final specIcon = _mySpecialty == 'learning_support'
        ? Icons.psychology
        : Icons.school;

    final specColor = _mySpecialty == 'learning_support'
        ? AppColors.purple
        : AppColors.navy;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          )),
                      Text(
                        'العمر: $age سنة'
                        '${disability.isNotEmpty ? ' • $disability' : ''}',
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('متاح',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orangeDeep,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (description.isNotEmpty)
              _infoRow('وصف الإعاقة', description, c),
            if (medicalHistory.isNotEmpty)
              _infoRow('التاريخ الطبي', medicalHistory, c),
            if (specialNeeds.isNotEmpty)
              _infoRow('احتياجات خاصة', specialNeeds, c),
            if (preferredStyle.isNotEmpty)
              _infoRow('أسلوب التعلم', preferredStyle, c),
            if (strengths.isNotEmpty)
              _chipsRow('نقاط القوة', strengths, c,
                  AppColors.greenDeep, c.tintGreen),
            if (challenges.isNotEmpty)
              _chipsRow('التحديات', challenges, c,
                  AppColors.orangeDeep, c.tintOrange),
            const SizedBox(height: 12),

            // ═══ زر الإضافة ═══
            if (!hasSpecialty)
              // ✅ لو التخصص غير محدد → زر يفتح الشاشة
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangeDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline, size: 20),
                  label: const Text(
                    '⚠️ حدد تخصصك أولاً',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChooseSpecialtyScreen(),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() => _mySpecialty = result);
                    }
                  },
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: specColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isAdding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(specIcon, size: 20),
                  label: Text(
                    isAdding ? 'جارٍ الإضافة...' : 'أضفني كـ$specType',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed:
                      isAdding ? null : () => _addMyselfToChild(child),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, JisrColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: c.muted,
                )),
          ),
          Expanded(
            child: Text(value,
                style:
                    TextStyle(fontSize: 13, color: c.body, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _chipsRow(String label, List<String> items, JisrColors c,
      Color color, Color bg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: c.muted,
                )),
          ),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: items
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(s,
                            style:
                                TextStyle(fontSize: 11, color: color)),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMyselfToChild(Map<String, dynamic> child) async {
    if (!await _checkVerification()) return;
    if (_mySpecialty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم تحديد تخصصك — راجع الدعم'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _mySpecialty == 'learning_support'
                  ? Icons.psychology
                  : Icons.school,
              color: _mySpecialty == 'learning_support'
                  ? AppColors.purple
                  : AppColors.navy,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('تأكيد الإضافة'),
          ],
        ),
        content: Text(
          'هل تريد إضافة "${child['name']}" لمتابعتك كـ'
          '${_mySpecialty == 'learning_support' ? 'مختص دعم تعليمي' : 'مختص تعليمي'}؟',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _mySpecialty == 'learning_support'
                  ? AppColors.purple
                  : AppColors.navy,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _approvingId = child['id']);

    try {
      final err = await ApiService.assignSpecialist(
        childId: child['id'],
        specialistId: _currentUserId!,
        specialty: _mySpecialty!,
      );
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $err'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تمت إضافة ${child['name']} لمتابعتك'),
            backgroundColor: Colors.green,
          ),
        );
        await _load();
      }
    } finally {
      if (mounted) setState(() => _approvingId = null);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  بطاقة الطفل المتابَع
  // ═══════════════════════════════════════════════════════════
  Widget _buildMyChildCard(Map<String, dynamic> row, JisrColors c) {
    final child = row['child'];
    final stats = row['stats'] as Map<String, dynamic>;
    final current = stats['current'];
    final name = (child['name'] ?? '').toString();
    final need = (child['disability_type'] ?? '').toString();
    final childId = child['id'];
    final approving = _approvingId == childId;
    final status = child['status'] ?? 'pending';
    final isPending = status == 'pending' || status == '';
    final color = AppColors
        .kidPalette[_rows.indexOf(row) % AppColors.kidPalette.length];

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
                    onTap: () async {
                      await AccessibilityService.instance.setActiveChild(
                        childId,
                        disabilityTypeHint:
                            child['disability_type']?.toString(),
                      );
                      if (!context.mounted) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChildProgressScreen(
                            childId: childId,
                            childName: name,
                          ),
                        ),
                      );
                      await AccessibilityService.instance
                          .setActiveChild(null);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: c.heading,
                            )),
                        if (need.isNotEmpty)
                          Text('الإعاقة: $need',
                              style: TextStyle(
                                  fontSize: 13, color: c.muted)),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${stats['pct']}% ⭐',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tealDeep,
                        )),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('بانتظار التقييم',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orangeDeep,
                            )),
                      ),
                  ],
                ),
              ],
            ),
            if (child['has_pending_learning_support_request'] == true) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.purple, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology,
                        color: AppColors.purple, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🧠 طلب دعم نفسي',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.purple,
                              )),
                          Text('ولي الأمر يطلب جلسة نفسية',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LearningSupportRequestsScreen(),
                        ),
                      ),
                      child: const Text('اعرض',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (current != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.tintOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('🕒 ${current['lesson_title'] ?? ''}',
                        style:
                            TextStyle(fontSize: 13, color: c.onTint)),
                  ),
                if ((stats['inProgress'] as int) > 0)
                  _CountBadge('${stats['inProgress']} قيد التنفيذ',
                      color: AppColors.blue),
                if ((stats['done'] as int) > 0)
                  _CountBadge('${stats['done']} ✅ مكتمل',
                      color: AppColors.lightTeal),
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
                          icon: const Icon(Icons.assessment,
                              color: Colors.white),
                          label: const Text('تقييم الطفل'),
                          onPressed: () => _openEvaluation(row),
                        )
                      : OutlinedButton.icon(
                          icon: const Icon(Icons.visibility),
                          label: const Text('عرض التقييم'),
                          onPressed: () => _viewEvaluation(childId),
                        ),
                ),
                if (!isPending && current != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightTeal,
                      ),
                      icon: approving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
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
            if (!isPending) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: AppColors.tealDeep,
                        side: const BorderSide(
                            color: AppColors.tealDeep, width: 1.5),
                      ),
                      icon: const Icon(Icons.article, size: 18),
                      label: const Text('تقرير المعلم',
                          style: TextStyle(fontSize: 13)),
                      onPressed: () => _openTeacherReport(row),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: AppColors.lightTeal,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('اكتب تقدّم',
                          style: TextStyle(fontSize: 13)),
                      onPressed: () => _writeProgressBasedOnReport(row),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: AppColors.teal,
                        side: const BorderSide(
                            color: AppColors.teal, width: 1.5),
                      ),
                      icon: const Icon(Icons.forum, size: 18),
                      label: const Text('دراسة الحالة',
                          style: TextStyle(fontSize: 13)),
                      onPressed: () =>
                          _openCaseDiscussion(childId: childId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.psychology, size: 18),
                      label: const Text('اقترح دعم',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => _recommendLearningSupport(row),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        foregroundColor: AppColors.purple,
                        side: const BorderSide(
                            color: AppColors.purple, width: 1.5),
                      ),
                      icon: const Icon(Icons.recommend, size: 16),
                      label: const Text('اقترح مختص دعم تعليمي',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      onPressed: () =>
                          _openSuggestSpecialist(row, 'learning_support'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(
                            color: AppColors.navy, width: 1.5),
                      ),
                      icon: const Icon(Icons.school, size: 16),
                      label: const Text('اقترح مختص تعليمي',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      onPressed: () =>
                          _openSuggestSpecialist(row, 'educational'),
                    ),
                  ),
                ],
              ),
            ],
            if (!isPending && child['current_plan_id'] != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.lightTeal,
                    side: const BorderSide(color: AppColors.lightTeal),
                  ),
                  icon: const Icon(Icons.rate_review),
                  label: const Text('تقييم الخطة الحالية'),
                  onPressed: () => _openPlanEvaluation(row),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openSuggestSpecialist(
      Map<String, dynamic> row, String specialty) async {
    if (!await _checkVerification()) return;
    if (!mounted) return;
    final child = row['child'];
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuggestSpecialistSheet(
        child: child,
        specialists: _specialists,
        specialty: specialty,
      ),
    );
    if (result == true) _load();
  }

  // ═══════════════════════════════════════════════════════════
  //  تبويب الدروس
  // ═══════════════════════════════════════════════════════════
  Widget _buildLessonsTab(JisrColors c) {
    if (_lessons.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.menu_book, size: 72, color: c.muted),
          const SizedBox(height: 16),
          Center(
            child: Text('لا توجد دروس بعد',
                style: TextStyle(fontSize: 18, color: c.muted)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('أضف درساً جديداً باستخدام زر +',
                style: TextStyle(fontSize: 14, color: c.muted)),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _lessons.length,
      itemBuilder: (context, i) => _buildLessonCard(_lessons[i], c),
    );
  }

  Widget _buildLessonCard(Map lesson, JisrColors c) {
    final title = (lesson['title'] ?? '').toString();
    final tag = _typeName(lesson['disability_type_id']);
    final targetType = lesson['target_type']?.toString() ?? 'everyone';

    String targetBadge;
    Color targetColor;
    switch (targetType) {
      case 'parents':
        targetBadge = '👪 لأولياء الأمور';
        targetColor = AppColors.purple;
        break;
      case 'byDisability':
        targetBadge = '🎯 حسب الإعاقة';
        targetColor = AppColors.teal;
        break;
      case 'specificChildren':
        final count = (lesson['target_child_ids'] as List?)?.length ?? 0;
        targetBadge = '👥 $count طلاب';
        targetColor = AppColors.teal;
        break;
      default:
        targetBadge = '🌍 للجميع';
        targetColor = AppColors.blue;
    }

    final hasVideo =
        (lesson['video_url']?.toString().isNotEmpty ?? false);
    final hasAudio =
        (lesson['audio_url']?.toString().isNotEmpty ?? false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: targetColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            hasVideo
                ? Icons.play_circle_fill
                : hasAudio
                    ? Icons.volume_up
                    : Icons.menu_book,
            size: 28,
            color: targetColor,
          ),
        ),
        title: Text(title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.heading,
            )),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tag != null)
              Text(tag, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: targetColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(targetBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: targetColor,
                  )),
            ),
          ],
        ),
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
      child: AddLessonSheet(
        types: _types,
        onClose: () => _setAdding(false),
        onCreated: (lesson) {
          inlineModalOpen.value = false;
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

// ═══════════════════════════════════════════════════════════
//  مكوّنات مساعدة
// ═══════════════════════════════════════════════════════════
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
            Text('$icon $value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                )),
            Text(label,
                style: TextStyle(fontSize: 10, color: c.muted),
                textAlign: TextAlign.center),
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
      child: Text(text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          )),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  _SuggestSpecialistSheet
// ═══════════════════════════════════════════════════════════
class _SuggestSpecialistSheet extends StatefulWidget {
  final Map child;
  final List specialists;
  final String specialty;

  const _SuggestSpecialistSheet({
    required this.child,
    required this.specialists,
    required this.specialty,
  });

  @override
  State<_SuggestSpecialistSheet> createState() =>
      _SuggestSpecialistSheetState();
}

class _SuggestSpecialistSheetState extends State<_SuggestSpecialistSheet> {
  int? _selectedId;
  final _reasonCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  String get _label =>
      widget.specialty == 'learning_support' ? 'مختص دعم تعليمي' : 'مختص تعليمي';

  Color get _color => widget.specialty == 'learning_support'
      ? AppColors.purple
      : AppColors.navy;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedId == null) {
      setState(() => _error = 'اختر مختصاً');
      return;
    }
    if (_reasonCtrl.text.trim().length < 10) {
      setState(() => _error = 'اكتب سبب التوصية (10 أحرف على الأقل)');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final err = await ApiService.suggestSpecialistToChild(
      childId: widget.child['id'],
      specialistId: _selectedId!,
      specialty: widget.specialty,
      reason: _reasonCtrl.text.trim(),
    );

    if (!mounted) return;
    if (err != null) {
      setState(() {
        _error = err;
        _saving = false;
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم إرسال التوصية لـ$_label'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final filtered = widget.specialists.where((s) {
      final spec = (s['specialty'] ?? '').toString().toLowerCase();
      if (spec.isEmpty) return true;
      return spec == widget.specialty ||
          spec.contains(widget.specialty == 'learning_support'
              ? 'نفس'
              : 'تعليم');
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.recommend, color: _color, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('اقتراح $_label',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        )),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: _color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيُرسَل إشعار للمختص المقترح لمتابعة ${widget.child['name']}.',
                        style: TextStyle(
                            fontSize: 12, color: c.onTint, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Text('لا يوجد مختصون متاحون',
                      style: TextStyle(color: c.muted),
                      textAlign: TextAlign.center),
                )
              else
                ...filtered.map<Widget>((s) {
                  final id = s['id'] as int;
                  return RadioListTile<int>(
                    value: id,
                    groupValue: _selectedId,
                    activeColor: _color,
                    title: Text(s['name']?.toString() ?? ''),
                    subtitle: Text(
                      s['email']?.toString() ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onChanged: (v) => setState(() => _selectedId = v),
                  );
                }),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonCtrl,
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: 'سبب التوصية *',
                  alignLabelWithHint: true,
                  hintText: 'لماذا ترشح هذا المختص؟',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
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
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _color,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: Text(_saving ? '...' : 'إرسال التوصية',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  _RecommendLearningSupportSheet
// ═══════════════════════════════════════════════════════════
class _RecommendLearningSupportSheet extends StatefulWidget {
  final Map child;
  const _RecommendLearningSupportSheet({required this.child});

  @override
  State<_RecommendLearningSupportSheet> createState() =>
      _RecommendLearningSupportSheetState();
}

class _RecommendLearningSupportSheetState extends State<_RecommendLearningSupportSheet> {
  final _descCtrl = TextEditingController();
  String? _reason;
  String _urgency = 'medium';
  bool _saving = false;
  String? _error;

  static const _reasons = [
    'يحتاج دعم نفسي متخصص',
    'ظهور علامات قلق مستمر',
    'تدهور في المزاج',
    'مشاكل في النوم',
    'سلوك انسحابي',
    'نوبات غضب متكررة',
    'يحتاج تقييم نفسي شامل',
    'أخرى',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_reason == null) {
      setState(() => _error = 'اختر سبب التوصية');
      return;
    }
    if (_descCtrl.text.trim().length < 15) {
      setState(() => _error = 'اكتب شرحاً (15 حرفاً على الأقل)');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService.authPost('/learning-support/recommendations', {
        'child_id': widget.child['id'],
        'reason': _reason,
        'description': _descCtrl.text.trim(),
        'urgency': _urgency,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إرسال التوصية لولي الأمر'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology,
                      color: AppColors.purple, size: 30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'اقتراح دعم نفسي — ${widget.child['name']}',
                      style: TextStyle(
                        fontSize: 17,
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
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(
                  labelText: 'سبب التوصية *',
                  prefixIcon: Icon(Icons.report_problem),
                ),
                items: _reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _reason = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'شرح مفصّل *',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _urgencyChip(
                        '🟢 منخفضة', 'low', AppColors.green),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _urgencyChip(
                        '🟡 متوسطة', 'medium', AppColors.orange),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child:
                        _urgencyChip('🔴 عاجلة', 'high', AppColors.red),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ],
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
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: Text(_saving ? '...' : 'إرسال لولي الأمر',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _urgencyChip(String label, String value, Color color) {
    final selected = _urgency == value;
    return GestureDetector(
      onTap: () => setState(() => _urgency = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:
              selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? color : Colors.grey.shade600,
            )),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  _LessonDetailSheet
// ═══════════════════════════════════════════════════════════
class _LessonDetailSheet extends StatelessWidget {
  final Map lesson;
  const _LessonDetailSheet({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final title = (lesson['title'] ?? '').toString();
    final content = (lesson['content'] ?? '').toString();
    final targetType = lesson['target_type']?.toString() ?? 'everyone';
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
                  child: Text(title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      )),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (targetType == 'parents')
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.family_restroom,
                        color: AppColors.purple, size: 16),
                    SizedBox(width: 4),
                    Text('درس موجّه لأولياء الأمور',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.purple,
                        )),
                  ],
                ),
              ),
            if (createdAt != null)
              Text(
                'تاريخ الإضافة: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            const SizedBox(height: 12),
            if (content.isNotEmpty)
              Text(content,
                  style: TextStyle(
                      fontSize: 16, height: 1.5, color: c.body)),
          ],
        ),
      ),
    );
  }
}