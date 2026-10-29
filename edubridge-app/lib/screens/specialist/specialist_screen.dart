import '../../l10n/l10n.dart';
import '../../utils/presentation_text.dart';

// lib/screens/specialist/specialist_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import '../interactive_lesson/starter_lesson_library_entry.dart';

import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../services/specialist_dashboard_repository.dart';
import '../../services/notification_listener_service.dart';
import '../child_accessibility/child_accessibility_settings_screen.dart';
import '../../theme.dart';
import '../../utils/navigation.dart';
import '../../widgets/accessibility/profile_avatar_button.dart';
import '../../widgets/dashboard_menu.dart';
import '../add_certificate_sheet.dart';
import '../add_lesson/add_lesson_sheet.dart';
import '../add_lesson/add_lesson_screen.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../choose_specialty_screen.dart';
import '../create_specialist_progress_screen.dart';
import '../evaluation/evaluation_sheet.dart';
import '../evaluation_history/evaluation_history_screen.dart';
import '../learning_support_requests/learning_support_requests_screen.dart';
import '../notifications_screen.dart';
import '../plan_evaluation_screen.dart';
import '../verify_identity/verify_identity_screen.dart';
import '../weekly_report_screen.dart';
import 'specialist_child_profile_screen.dart';
import 'specialist_waiting_empty_s29.dart';
import 'support_target_dialog_s28.dart';
import '../login_screen.dart';

import 'specialist_bottom_navigation.dart';
import 'specialist_child_search_dialog.dart';
import 'specialist_dashboard_body.dart';
import 'specialist_dashboard_navigation.dart';
import 'specialist_verification_dialog.dart';
import '../specialist_schools/specialist_schools_screen.dart';

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
part 'specialist_count_badge.dart';
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
      builder: (dialogContext) => SpecialistVerificationDialog(
        onVerify: () async {
          Navigator.pop(dialogContext);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VerifyIdentityScreen()),
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
    final result = await SpecialistChildSearchDialog.show(
      context,
      _searchQuery,
    );
    if (result != null && mounted) {
      setState(() {
        _searchQuery = result.trim();
        _tabIndex = 0;
      });
    }
  }

  Future<void> _openSchools() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const SpecialistSchoolsScreen()));
    if (mounted) await _load();
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
          100 +
              (MediaQuery.textScalerOf(context).scale(20) - 20)
                      .clamp(0.0, 80.0)
                      .toDouble() *
                  2,
        ),
        child: _buildHeader(
          context: context,
          c: c,
          tabIndex: _tabIndex,
          specialty: _mySpecialty,
          menuActions: specialistDashboardMenuActions(
            context: context,
            searchQuery: _searchQuery,
            onLessons: () => setState(() => _tabIndex = 1),
            onSearch: _openChildSearch,
            onAddCertificate: _openAddCertificate,
            onLogout: _logoutSpecialist,
            onSchools: _openSchools,
          ),
        ),
      ),
      body: SpecialistDashboardBody(
        tabIndex: _tabIndex,
        loading: _loading,
        hasError: _error != null,
        searchQuery: _searchQuery,
        onSearchChanged: (value) => setState(() => _searchQuery = value),
        onRefresh: _refresh,
        filter: _buildFilterCard(c),
        pendingCount: _pendingCount,
        doneToday: _doneToday,
        pendingProgress: _pendingProgress,
        errorBuilder: (_) => _buildError(),
        progressBuilder: (_) => buildProgressTab(context, c),
        lessonsBuilder: (_) => buildLessonsTab(context, c),
        overlay: _adding ? _buildAddModal() : null,
      ),
      bottomNavigationBar: _adding
          ? null
          : SpecialistBottomNavigation(
              tabIndex: _tabIndex,
              onSelected: (index) => openSpecialistDashboardDestination(
                context,
                index,
                onChildren: () => setState(() => _tabIndex = 0),
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
