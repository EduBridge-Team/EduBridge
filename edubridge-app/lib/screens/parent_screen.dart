// lib/screens/parent_screen.dart
// لوحة ولي الأمر — بهوية EduBridge
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/adaptive_helper.dart';
import '../widgets/accessibility/adaptive_button.dart';
import '../widgets/accessibility/adaptive_card.dart';
import '../widgets/accessibility/adaptive_text.dart';
import '../widgets/accessibility/adaptive_wrapper.dart';
import '../widgets/accessibility/profile_avatar_button.dart';
import '../widgets/legal_links_button.dart';
import '../widgets/dashboard_menu.dart';
import 'add_child/add_child_screen.dart';
import 'child_homework/child_homework_screen.dart';
import 'child_lessons/child_lessons_screen.dart';
import 'notifications_screen.dart';
import 'support_sheet.dart';
import 'child_progress_screen.dart';
import 'edit_child_screen.dart';
import 'children_accessibility_overview_screen.dart';
import 'weekly_report_screen.dart';
import 'care_team_screen.dart';
import 'create_learning_support_request_screen.dart';
import 'add_certificate_sheet.dart';
import 'chats_screen.dart';
import 'parent_lessons_screen.dart';
import 'login_screen.dart';

part 'parent_screen_widgets.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  List _children = [];
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
      final res = await ApiService.authGet('/children');
      final data = jsonDecode(res.body);
      if (!mounted) return;

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
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  Future<void> _openChildDetails(Map child) async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildLessonsScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
          age: child['age'] is int ? child['age'] as int : 8,
          disabilityType: child['disability_type']?.toString(),
          parentPhone: child['parent_phone']?.toString(),
        ),
      ),
    );
  }

  void _openHomework(Map child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildHomeworkScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
        ),
      ),
    );
  }

  void _openWeeklyReport(Map child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeeklyReportScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
        ),
      ),
    );
  }

  void _openCareTeam(Map child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CareTeamScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
        ),
      ),
    );
  }

  void _openChildProgress(Map child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildProgressScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
        ),
      ),
    );
  }

  Future<void> _openLearningSupportRequest(Map child) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateLearningSupportRequestScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
        ),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _openEditChild(Map child) async {
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
  }

  Future<void> _openAddChild() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddChildScreen()),
    );
    if (result == true) _loadData();
  }

  void _openParentLessons() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ParentLessonsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveWrapper(
      screenTitle: 'لوحة ولي الأمر',
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: _buildBody(),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddChild,
          icon: const Icon(AppIcons.add),
          label: const Text(
            'إضافة طفل',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 72,
      titleSpacing: 0,
      centerTitle: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.headerGradient,
        ),
      ),
      leadingWidth: 72,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: 8),
        child: Center(
          child: DashboardMenu(
            showMicrophoneToggle: true,
            iconSize: 26,
            iconColor: Colors.white,
            actions: [
              DashboardMenuAction(
                id: 'notifications',
                label: 'الإشعارات',
                icon: AppIcons.notifications,
                onSelected: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              DashboardMenuAction(
                id: 'parent_lessons',
                label: 'دروس ولي الأمر',
                icon: AppIcons.parent,
                onSelected: _openParentLessons,
              ),
              DashboardMenuAction(
                id: 'accessibility',
                label: 'احتياجات الأبناء',
                icon: Icons.accessibility_new,
                onSelected: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ChildrenAccessibilityOverviewScreen(),
                  ),
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
                id: 'chats',
                label: 'المحادثات',
                icon: AppIcons.chat,
                onSelected: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatsScreen()),
                ),
              ),
              DashboardMenuAction(
                id: 'certificate',
                label: 'إضافة شهادة',
                icon: AppIcons.certificate,
                onSelected: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddCertificateSheet(onSaved: _loadData),
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
                onSelected: () async {
                  final navigator = Navigator.of(context);
                  await ApiService.logout();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      title: const SizedBox.shrink(),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 16),
          child: Center(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assets/brand_logo.png',
                width: 136,
                height: 38,
                fit: BoxFit.contain,
                alignment: AlignmentDirectional.centerEnd,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ],
    );
  }

}
