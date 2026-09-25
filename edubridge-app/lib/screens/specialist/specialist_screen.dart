// lib/screens/specialist/specialist_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/accessibility_service.dart';
import '../../services/api_service.dart';
import '../../services/notification_listener_service.dart';
import '../../theme.dart';
import '../../utils/navigation.dart';
import '../add_lesson/add_lesson_sheet.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../child_progress_screen.dart';
import '../choose_specialty_screen.dart';
import '../create_specialist_progress_screen.dart';
import '../evaluation/evaluation_sheet.dart';
import '../learning_support_meetings_screen.dart';
import '../learning_support_requests/learning_support_requests_screen.dart';
import '../notifications_screen.dart';
import '../plan_evaluation_screen.dart';
import '../specialist_suggestions_screen.dart';
import '../verify_identity/verify_identity_screen.dart';
import '../weekly_report_screen.dart';
import '../welcome_screen.dart';
import '../../widgets/accessibility/profile_avatar_button.dart';
import '../../widgets/dashboard_menu.dart';

part 'specialist_header.dart';
part 'specialist_progress_tab.dart';
part 'specialist_child_cards.dart';
part 'specialist_lessons_tab.dart';
part 'specialist_suggest_sheet.dart';
part 'specialist_recommend_sheet.dart';
part 'specialist_lesson_detail_sheet.dart';
part 'specialist_stats_widgets.dart';

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
  List _specialists = [];
  bool _loading = true;
  String? _error;
  int? _approvingId;
  bool _adding = false;
  String _searchQuery = '';

  bool _showOnlyMine = true;
  int? _currentUserId;
  String? _mySpecialty;

  bool _verificationDialogShown = false;
  bool _specialtyDialogShown = false;

  // ═══════════════════════════════════════════════════════════
  //  Lifecycle
  // ═══════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  @override
  void dispose() {
    if (_adding) inlineModalOpen.value = false;
    super.dispose();
  }

  Future<void> _loadUserAndData() async {
    _currentUserId = await ApiService.getUserId();
    await _load();
    await _checkSpecialty();
    _checkAndShowVerificationDialog();
  }

  void _setAdding(bool value) {
    inlineModalOpen.value = value;
    setState(() => _adding = value);
  }

  // ═══════════════════════════════════════════════════════════
  //  التخصص — اختيار أول مرة
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
      await _load();
    } else {
      _specialtyDialogShown = false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  تحميل البيانات الرئيسية
  // ═══════════════════════════════════════════════════════════
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

      String? specialty;

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
        debugPrint('فشل /me: $e');
      }

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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  التوثيق
  // ═══════════════════════════════════════════════════════════
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
                  color: AppColors.brandBlueLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.verified,
                    size: 48, color: AppColors.brandBlueLight),
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
                    backgroundColor: AppColors.brandBlueLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(AppIcons.verified, size: 22),
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
            content: Text('يرجى توثيق الهوية أولاً'),
            backgroundColor: AppColors.brandBlueLight,
          ),
        );
      }
      return false;
    }
    return true;
  }

  // ═══════════════════════════════════════════════════════════
  //  Helpers — compute stats
  // ═══════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════
  //  الفلترة والتخصصات
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

    int supportCount = 0;
    int eduCount = 0;
    int unknownCount = 0;

    for (final id in specIds) {
      final s = _specialists.firstWhere(
        (u) => u['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      final spec = (s['specialty'] ?? '').toString().toLowerCase();
      if (spec == 'learning_support' || spec.contains('نفس')) {
        supportCount++;
      } else if (spec == 'educational' || spec.contains('تعليم')) {
        eduCount++;
      } else {
        unknownCount++;
      }
    }
    if (supportCount >= 1 && eduCount >= 1) return true;
    if (supportCount + eduCount == 0 && unknownCount >= 2) return true;
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

  int get _pendingCount => _pendingChildren.length;
  int get _doneToday =>
      _rows.fold(0, (s, r) => s + (r['stats']['doneToday'] as int));
  int get _pendingProgress =>
      _rows.fold(0, (s, r) => s + (r['stats']['inProgress'] as int));

  // ═══════════════════════════════════════════════════════════
  //  الإجراءات — Approve / Evaluation / Reports
  // ═══════════════════════════════════════════════════════════
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
            content: Text('تم اعتماد إنجاز الدرس'),
            backgroundColor: AppColors.brandTealDeep,
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

  Future<void> _openEvaluation(Map<String, dynamic> row) async {
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
            return _buildEmptyEvaluationModal();
          }
          final evaluation = snapshot.data!.last;
          return _buildEvaluationViewModal(evaluation);
        },
      ),
    );
  }

  Widget _buildEmptyEvaluationModal() {
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
        children: [
          const Icon(AppIcons.evaluate, size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          Text('لا يوجد تقييم مسجل',
              style: TextStyle(color: c.muted)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
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
                const Icon(AppIcons.evaluate, color: AppColors.brandBlueLight),
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
                  icon: const Icon(AppIcons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (date != null)
              Text('التاريخ: ${date.day}/${date.month}/${date.year}',
                  style: TextStyle(color: c.muted)),
            const SizedBox(height: 12),
            _detailRow('التقييم المعرفي', evaluation['cognitive_assessment']),
            _detailRow('التقييم الحركي', evaluation['motor_assessment']),
            _detailRow(
                'التفاعل أثناء التعلم', evaluation['emotional_assessment']),
            _detailRow('التقييم الاجتماعي', evaluation['social_assessment']),
            _detailRow('التوصيات', evaluation['recommendations']),
            _detailRow('الخطة التعليمية', evaluation['educational_plan']),
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
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  التنقل بين الشاشات
  // ═══════════════════════════════════════════════════════════
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
    );
  }

  void _openLearningSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LearningSupportMeetingsScreen(),
      ),
    );
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

  Future<void> _recommendLearningSupport(
      Map<String, dynamic> row) async {
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

  Future<void> _openSuggestSpecialist(
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
  //  إضافة نفسي كمسؤول عن الطفل
  // ═══════════════════════════════════════════════════════════
  Future<void> _addMyselfToChild(Map<String, dynamic> child) async {
    if (!await _checkVerification()) return;
    if (!mounted) return;
    if (_mySpecialty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم تحديد تخصصك — راجع الدعم'),
          backgroundColor: AppColors.red,
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
                  ? AppIcons.specialist
                  : AppIcons.lesson,
              color: _mySpecialty == 'learning_support'
                  ? AppColors.brandTealDeep
                  : AppColors.brandBlue,
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
                  ? AppColors.brandTealDeep
                  : AppColors.brandBlue,
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
          SnackBar(content: Text(err), backgroundColor: AppColors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة ${child['name']} لمتابعتك'),
            backgroundColor: AppColors.green,
          ),
        );
        await _load();
      }
    } finally {
      if (mounted) setState(() => _approvingId = null);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context, c, _tabIndex, _mySpecialty),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (_tabIndex == 0)
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'ابحث عن طفل...',
                            prefixIcon: Icon(AppIcons.search),
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
                    _buildNotificationBell(),
                  ],
                ),
              ),
              if (_tabIndex == 0 && !_loading) ...[
                _buildFilterCard(c),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _StatsCard(
                        icon: AppIcons.clock,
                        value: '$_pendingCount',
                        label: 'بانتظار التقييم',
                        color: AppColors.brandBlue,
                      ),
                      const SizedBox(width: 8),
                      _StatsCard(
                        icon: AppIcons.check,
                        value: '$_doneToday',
                        label: 'منجز اليوم',
                        color: AppColors.brandTealDeep,
                      ),
                      const SizedBox(width: 8),
                      _StatsCard(
                        icon: AppIcons.progress,
                        value: '$_pendingProgress',
                        label: 'قيد التنفيذ',
                        color: AppColors.brandTealLight,
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
                          : (_tabIndex == 0
                              ? buildProgressTab(context, c)
                              : buildLessonsTab(context, c)),
                ),
              ),
            ],
          ),
          if (_adding) _buildAddModal(),
        ],
      ),
      bottomNavigationBar: _adding
          ? null
          : NavigationBar(
              selectedIndex: _tabIndex,
              onDestinationSelected: (i) => setState(() => _tabIndex = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(AppIcons.progress),
                  selectedIcon: Icon(Icons.insights),
                  label: 'التقدّم',
                ),
                NavigationDestination(
                  icon: Icon(AppIcons.lesson),
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
              icon: const Icon(AppIcons.add),
              label: const Text('إضافة درس'),
              backgroundColor: AppColors.brandTealDeep,
            )
          : null,
    );
  }

  Widget _buildNotificationBell() {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationListenerService.instance.unreadCount,
      builder: (context, count, _) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(AppIcons.notifications),
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
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$count',
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
        );
      },
    );
  }

  Widget _buildFilterCard(JisrColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _showOnlyMine
              ? AppColors.brandBlue.withValues(alpha: 0.1)
              : AppColors.brandTealDeep.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                _showOnlyMine ? AppColors.brandBlue : AppColors.brandTealDeep,
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
                    ? AppColors.brandBlue
                    : AppColors.brandTealDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                _showOnlyMine ? AppIcons.profile : AppIcons.clock,
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
                              ? AppColors.brandBlue
                              : AppColors.brandTealDeep,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _showOnlyMine
                              ? AppColors.brandBlue
                              : AppColors.brandTealDeep,
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
              activeThumbColor: AppColors.brandBlue,
              inactiveThumbColor: AppColors.brandTealDeep,
              inactiveTrackColor:
                  AppColors.brandTeal.withValues(alpha: 0.35),
              onChanged: (v) => setState(() => _showOnlyMine = v),
            ),
          ],
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
                  style:
                      const TextStyle(fontSize: 16, color: AppColors.red)),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(AppIcons.refresh, size: 28),
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

  Widget _buildAddModal() {
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
              content: Text('تم إضافة الدرس بنجاح'),
              backgroundColor: AppColors.brandTealDeep,
            ),
          );
        },
      ),
    );
  }
}