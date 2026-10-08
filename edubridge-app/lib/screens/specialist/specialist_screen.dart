import '../../utils/presentation_text.dart';
// lib/screens/specialist/specialist_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../child_accessibility/child_accessibility_settings_screen.dart';
import '../../theme.dart';
import '../../utils/navigation.dart';
import '../../widgets/accessibility/profile_avatar_button.dart';
import '../../widgets/dashboard_menu.dart';
import '../../widgets/legal_links_button.dart';
import '../add_certificate_sheet.dart';
import '../add_lesson/add_lesson_sheet.dart';
import '../add_lesson/add_lesson_screen.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../chats_screen.dart';
import '../choose_specialty_screen.dart';
import '../create_specialist_progress_screen.dart';
import '../evaluation/evaluation_sheet.dart';
import '../learning_support_requests/learning_support_requests_screen.dart';
import '../notifications_screen.dart';
import '../plan_evaluation_screen.dart';
import '../support_sheet.dart';
import '../verify_identity/verify_identity_screen.dart';
import '../weekly_report_screen.dart';
import 'specialist_child_profile_screen.dart';
import '../login_screen.dart';

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
  final int initialTab;
  const SpecialistDashboardScreen({super.key, this.initialTab = 0});

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

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;
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

  Future<void> _setAdding(bool value) async {
    if (!value) {
      inlineModalOpen.value = false;
      setState(() => _adding = false);
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddLessonScreen(types: _types)),
    );
    if (result != null && mounted) await _load();
  }

  Future<void> _checkSpecialty() async {
    if (_specialtyDialogShown || _mySpecialty != null || !mounted) return;
    _specialtyDialogShown = true;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ChooseSpecialtyScreen()),
    );
    if (!mounted) return;

    if (result != null) {
      setState(() => _mySpecialty = result);
      await _load();
    } else {
      _specialtyDialogShown = false;
    }
  }

  Future<void> _refresh() => _load(showLoader: false);

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (_error != null) {
      setState(() => _error = null);
    }

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
        final pRes = await ApiService.authGet('/progress/child/${child['id']}');
        final pData = jsonDecode(pRes.body);
        final progress = pRes.statusCode == 200 ? (pData['progress'] ?? []) : [];
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
          final spec = (me['specialty'] ?? '').toString().toLowerCase().trim();
          if (spec == 'learning_support' || spec.contains('نفس')) {
            specialty = 'learning_support';
          } else if (spec == 'educational' || spec.contains('تعليم')) {
            specialty = 'educational';
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
        final spec = (meUser['specialty'] ?? '').toString().toLowerCase().trim();
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

  Future<void> _checkAndShowVerificationDialog() async {
    if (_verificationDialogShown) return;
    final isVerified = await ApiService.isVerified();
    if (isVerified || !mounted) return;
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
                child: const Icon(
                  AppIcons.verified,
                  size: 48,
                  color: AppColors.brandBlueLight,
                ),
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
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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

  Future<void> _openChildSearch() async {
    final controller = TextEditingController(text: _searchQuery);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('البحث عن طفل'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'اكتب اسم الطفل...',
            prefixIcon: Icon(AppIcons.search),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, ''),
              child: const Text('مسح البحث'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('بحث'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && mounted) {
      setState(() {
        _searchQuery = result.trim();
        _tabIndex = 0;
      });
    }
  }

  List<DashboardMenuAction> _buildMenuActions() {
    return [
      DashboardMenuAction(
        id: 'search_children',
        label: _searchQuery.isEmpty ? 'البحث عن طفل' : 'تعديل بحث الأطفال',
        icon: AppIcons.search,
        onSelected: _openChildSearch,
      ),
      DashboardMenuAction(
        id: 'case_discussion',
        label: 'دراسات الحالة',
        icon: AppIcons.forum,
        onSelected: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CaseDiscussionScreen()),
        ),
      ),
      DashboardMenuAction(
        id: 'support_requests',
        label: 'طلبات الدعم',
        icon: AppIcons.specialist,
        onSelected: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LearningSupportRequestsScreen(),
          ),
        ),
      ),
      DashboardMenuAction(
        id: 'add_certificate',
        label: 'إضافة شهادة',
        icon: AppIcons.certificate,
        onSelected: _openAddCertificate,
      ),
      DashboardMenuAction(
        id: 'chats',
        label: 'المحادثات',
        icon: AppIcons.chat,
        onSelected: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatsScreen()),
        ),
      ),
      DashboardMenuAction(
        id: 'support',
        label: 'الدعم الفني',
        icon: AppIcons.support,
        onSelected: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const SupportSheet(),
        ),
      ),
      DashboardMenuAction(
        id: 'legal',
        label: 'الخصوصية والحساب',
        icon: AppIcons.privacy,
        onSelected: () => const LegalLinksButton().show(context),
      ),
      DashboardMenuAction(
        id: 'logout',
        label: 'تسجيل الخروج',
        icon: AppIcons.logout,
        destructive: true,
        onSelected: _logoutSpecialist,
      ),
    ];
  }

  Future<void> _openAddCertificate() async {
    if (!await _checkVerification()) return;
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCertificateSheet(onSaved: _load),
    );
  }

  Future<void> _logoutSpecialist() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(
                context: context,
                c: c,
                tabIndex: _tabIndex,
                specialty: _mySpecialty,
                menuActions: _buildMenuActions(),
              ),
              if (_tabIndex == 0 && _searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InputChip(
                      avatar: const Icon(AppIcons.search, size: 17),
                      label: Text('بحث: $_searchQuery'),
                      onDeleted: () => setState(() => _searchQuery = ''),
                    ),
                  ),
                ),
              if (_tabIndex == 0 && !_loading) ...[
                const SizedBox(height: 12),
                _buildFilterCard(c),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _StatsCard(
                        icon: AppIcons.clock,
                        value: '$_pendingCount',
                        label: 'بانتظار التقييم',
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 7),
                      _StatsCard(
                        icon: AppIcons.check,
                        value: '$_doneToday',
                        label: 'منجز اليوم',
                        color: AppColors.brandTealDeep,
                      ),
                      const SizedBox(width: 7),
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
                  onRefresh: _refresh,
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
                  label: 'الطلاب',
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
              label: const Text(
                'إضافة درس',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
    );
  }
}
