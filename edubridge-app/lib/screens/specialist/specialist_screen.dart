import '../../l10n/l10n.dart';
import '../../utils/presentation_text.dart';
// lib/screens/specialist/specialist_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../services/specialist_dashboard_repository.dart';
import '../../services/notification_listener_service.dart';
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
import 'specialist_waiting_empty_s29.dart';
import 'support_target_dialog_s28.dart';
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
part 'specialist_lesson_recommendation_sheet.dart';
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
  int? _selectedLessonTypeId;
  List<Map<String, dynamic>> _rows = [];
  List _lessons = [];
  List _types = [];
  List _teachers = [];
  List _specialists = [];
  bool _loading = true;
  Object? _error;
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
      final data = await SpecialistDashboardRepository().load(
        currentUserId: _currentUserId,
      );
      if (!mounted) return;
      setState(() {
        _rows = data.rows;
        _lessons = data.lessons;
        _types = data.types;
        _teachers = data.teachers;
        _specialists = data.specialists;
        _mySpecialty = data.specialty;
        _loading = false;
      });
    } on SpecialistDashboardLoadException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message ?? SharedUiMessage.dashboardLoadFailed;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = SharedUiMessage.connectionFailed;
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
                context.l10n.verificationRequired,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: JisrColors.of(context).heading,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.specialistVerificationDescription,
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
                  label: Text(
                    context.l10n.verifyIdentityAndCertificate,
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
          SnackBar(
            content: Text(context.l10n.verifyIdentityFirst),
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
        title: Text(context.l10n.searchForChild),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.l10n.enterChildName,
            prefixIcon: Icon(AppIcons.search),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, ''),
              child: Text(context.l10n.clearSearch),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(context.l10n.search),
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
        id: 'specialist_lessons',
        label: context.l10n.lessons,
        icon: AppIcons.lesson,
        onSelected: () => setState(() => _tabIndex = 1),
      ),
      DashboardMenuAction(
        id: 'search_children',
        label: _searchQuery.isEmpty ? context.l10n.searchForChild : context.l10n.editChildSearch,
        icon: AppIcons.search,
        onSelected: _openChildSearch,
      ),
      DashboardMenuAction(
        id: 'case_discussion',
        label: context.l10n.caseStudies,
        icon: AppIcons.forum,
        onSelected: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CaseDiscussionScreen()),
        ),
      ),
      DashboardMenuAction(
        id: 'support_requests',
        label: context.l10n.supportRequests,
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
        label: context.l10n.addCertificate,
        icon: AppIcons.certificate,
        onSelected: _openAddCertificate,
      ),
      DashboardMenuAction(
        id: 'chats',
        label: context.l10n.conversations,
        icon: AppIcons.chat,
        onSelected: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatsScreen()),
        ),
      ),
      DashboardMenuAction(
        id: 'support',
        label: context.l10n.technicalSupport,
        icon: AppIcons.support,
        onSelected: () => SupportSheet.show(context),
      ),
      DashboardMenuAction(
        id: 'about_app',
        label: context.l10n.aboutApp,
        icon: Icons.info_outline,
        onSelected: () => showAboutDialog(
          context: context,
          applicationName: 'EduBridge',
          children: [
            Text(context.l10n.aboutEduBridge),
          ],
        ),
      ),
      DashboardMenuAction(
        id: 'legal',
        label: context.l10n.privacyAndAccount,
        icon: AppIcons.privacy,
        onSelected: () => const LegalLinksButton().show(context),
      ),
      DashboardMenuAction(
        id: 'logout',
        label: context.l10n.logout,
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          100 + (MediaQuery.textScalerOf(context).scale(20) - 20)
              .clamp(0.0, 80.0).toDouble() * 2,
        ),
        child: _buildHeader(
            context: context,
            c: c,
            tabIndex: _tabIndex,
            specialty: _mySpecialty,
            menuActions: _buildMenuActions(),
          ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_tabIndex == 0) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: TextFormField(
                    initialValue: _searchQuery,
                    textInputAction: TextInputAction.search,
                    textDirection: Directionality.of(context),
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim()),
                    decoration: InputDecoration(
                      hintText: context.l10n.searchChildrenByName,
                      prefixIcon: const Icon(
                        AppIcons.search,
                        color: Color(0xFF1A73C9),
                      ),
                      filled: true,
                      fillColor: c.card,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: c.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF1A73C9),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFilterCard(c),
              ],
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (_tabIndex == 0 && !_loading)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                _StatsCard(
                                  value: '$_pendingCount',
                                  label: context.l10n.awaitingAssessment,
                                  color: AppColors.blue,
                                ),
                                const SizedBox(width: 7),
                                _StatsCard(
                                  value: '$_doneToday',
                                  label: context.l10n.completedToday,
                                  color: AppColors.brandTealDeep,
                                ),
                                const SizedBox(width: 7),
                                _StatsCard(
                                  value: '$_pendingProgress',
                                  label: context.l10n.inProgress,
                                  color: AppColors.brandTeal,
                                ),
                              ],
                            ),
                          ),
                        ),
                if (_loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildError(),
                  )
                else if (_tabIndex == 0)
                  buildProgressTab(context, c)
                else
                  buildLessonsTab(context, c),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_adding) _buildAddModal(),
        ],
      ),
      bottomNavigationBar: _adding
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF8FA5B5), width: 1.5),
                ),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: c.card,
                  indicatorColor: _tabIndex == 1
                      ? Colors.transparent
                      : const Color(0xFFE1F0FF),
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => TextStyle(
                      fontSize: 12,
                      fontWeight: states.contains(WidgetState.selected) &&
                              _tabIndex == 0
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: states.contains(WidgetState.selected) &&
                              _tabIndex == 0
                          ? const Color(0xFF1867BD)
                          : c.muted,
                    ),
                  ),
                  iconTheme: WidgetStateProperty.resolveWith(
                    (states) => IconThemeData(
                      size: 23,
                      color: states.contains(WidgetState.selected) &&
                              _tabIndex == 0
                          ? const Color(0xFF1867BD)
                          : c.muted,
                    ),
                  ),
                ),
                child: NavigationBar(
                  height: 76,
                  selectedIndex: 0,
                  onDestinationSelected: (i) {
                    if (i == 0) {
                      if (_tabIndex != 0) setState(() => _tabIndex = 0);
                      return;
                    }
                    final Widget destination;
                    switch (i) {
                      case 1:
                        destination = const CaseDiscussionScreen();
                        break;
                      case 2:
                        destination = const ChatsScreen();
                        break;
                      case 3:
                        destination = const LearningSupportRequestsScreen();
                        break;
                      default:
                        return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => destination),
                    );
                  },
                  destinations: [
                    NavigationDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people_rounded),
                      label: context.l10n.children,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.description_outlined),
                      label: context.l10n.caseStudies,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.chat_bubble_outline),
                      label: context.l10n.conversations,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.inbox_outlined),
                      label: context.l10n.supportRequests,
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _tabIndex == 1 && !_adding
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1769C2),
              foregroundColor: Colors.white,
              onPressed: () async {
                if (await _checkVerification()) _setAdding(true);
              },
              icon: const Icon(AppIcons.add),
              label: Text(
                context.l10n.suggestLesson,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
    );
  }
}


/// Open the existing S22 specialist recommendation from a child's own file.
/// This deliberately reuses the established API-backed dialog and validation,
/// rather than adding an unrelated dashboard quick action.
Future<bool> showChildSpecialistSuggestion(
  BuildContext context, {
  required Map<String, dynamic> child,
}) async {
  if (!await ApiService.isVerified()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.verifyIdentityFirst)),
      );
    }
    return false;
  }

  try {
    final specialists = await ApiService.getUsers(role: 'specialist');
    if (!context.mounted) return false;
    final selected = await showDialog<bool>(
      context: context,
      builder: (_) => _SuggestSpecialistSheet(
        child: child,
        specialists: specialists,
        specialty: 'learning_support',
        figmaS22: true,
      ),
    );
    return selected == true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.specialistsLoadFailed)),
      );
    }
    return false;
  }
}
