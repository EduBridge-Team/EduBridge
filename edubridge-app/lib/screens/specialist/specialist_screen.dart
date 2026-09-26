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
import '../learning_support_requests/learning_support_requests_screen.dart';
import '../notifications_screen.dart';
import '../plan_evaluation_screen.dart';
import '../verify_identity/verify_identity_screen.dart';
import '../weekly_report_screen.dart';
import '../../widgets/accessibility/profile_avatar_button.dart';
import '../../widgets/dashboard_menu.dart';

part 'specialist_header.dart';
part 'specialist_progress_tab.dart';
part 'specialist_child_cards.dart';
part 'specialist_available_child_card.dart';
part 'specialist_my_child_card.dart';
part 'specialist_lessons_tab.dart';
part 'specialist_suggest_sheet.dart';
part 'specialist_recommend_sheet.dart';
part 'specialist_lesson_detail_sheet.dart';
part 'specialist_stats_widgets.dart';
part 'specialist_dashboard_widgets.dart';
part 'specialist_dashboard_logic.dart';
part 'specialist_evaluation_logic.dart';
part 'specialist_dashboard_actions.dart';

class SpecialistDashboardScreen extends StatefulWidget {
  const SpecialistDashboardScreen({super.key});

  @override
  State<SpecialistDashboardScreen> createState() =>
      _SpecialistDashboardScreenState();
}

class _SpecialistDashboardScreenState extends State<SpecialistDashboardScreen> {
  void _refreshState(VoidCallback callback) => setState(callback);

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
                  color: AppColors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.verified,
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
            backgroundColor: AppColors.orange,
          ),
        );
      }
      return false;
    }
    return true;
  }

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
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 8),
                      _StatsCard(
                        icon: AppIcons.check,
                        value: '$_doneToday',
                        label: 'منجز اليوم',
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 8),
                      _StatsCard(
                        icon: AppIcons.progress,
                        value: '$_pendingProgress',
                        label: 'قيد التنفيذ',
                        color: AppColors.brandTeal,
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
              backgroundColor: AppColors.green,
            )
          : null,
    );
  }


}
