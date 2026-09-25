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
          label: const Text('إضافة طفل'),
          backgroundColor: AppColors.brandBlue,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      ),
      leadingWidth: 70,
      leading: const Center(child: ProfileAvatarButton(size: 44)),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/brand_icon.png', width: 32, height: 32),
          const SizedBox(width: 8),
          const Text(
            'EduBridge',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        DashboardMenu(
          showMicrophoneToggle: true,
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
              label: 'دروس لولي الأمر',
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
                navigator.pushReplacementNamed('/home');
              },
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AdaptiveHelper.spacing),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<String?>(
            future: ApiService.getName(),
            builder: (context, snap) {
              final name = snap.data ?? 'ولي الأمر';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdaptiveText(
                    'مرحباً $name',
                    type: AdaptiveTextType.title,
                    color: Colors.white,
                  ),
                  SizedBox(height: AdaptiveHelper.spacing / 3),
                  AdaptiveText(
                    'أضف أطفالك وتابع تقدمهم التعليمي',
                    type: AdaptiveTextType.caption,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorState();
    }
    if (_children.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(AdaptiveHelper.spacing),
      itemCount: _children.length,
      itemBuilder: (context, i) => _buildChildCard(_children[i], i),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AdaptiveHelper.spacing * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.error,
              size: AdaptiveHelper.iconSize * 2,
              color: AppColors.red,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            AdaptiveText(
              _error!,
              textAlign: TextAlign.center,
              color: AppColors.red,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            AdaptiveButton(
              label: 'إعادة المحاولة',
              icon: AppIcons.refresh,
              onPressed: _loadData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AdaptiveHelper.spacing * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: AdaptiveHelper.iconSize * 2,
              color: AppColors.muted,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            const AdaptiveText(
              'لا يوجد أطفال مسجلون بعد',
              type: AdaptiveTextType.subtitle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AdaptiveHelper.spacing / 2),
            AdaptiveText(
              'اضغط على زر + لإضافة طفل جديد',
              type: AdaptiveTextType.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(Map child, int index) {
    final name = (child['name'] ?? '').toString();
    final age = child['age'] ?? '?';
    final status = child['status'];
    final disabilityType = child['disability_type'] ?? 'غير محدد';
    final color = AppColors.kidPalette[index % AppColors.kidPalette.length];

    return Padding(
      padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
      child: AdaptiveCard(
        onTap: () => _openChildDetails(child),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── الرأس ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(name, color),
                SizedBox(width: AdaptiveHelper.spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdaptiveText(
                        name,
                        type: AdaptiveTextType.subtitle,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: AdaptiveHelper.spacing / 4),
                      AdaptiveText(
                        'العمر: $age سنة',
                        type: AdaptiveTextType.caption,
                      ),
                      AdaptiveText(
                        'الإعاقة: $disabilityType',
                        type: AdaptiveTextType.caption,
                      ),
                      if (child['assigned_teacher_name'] != null)
                        AdaptiveText(
                          'المعلم: ${child['assigned_teacher_name']}',
                          type: AdaptiveTextType.caption,
                          color: AppColors.brandBlue,
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),

            SizedBox(height: AdaptiveHelper.spacing),

            // ─── الصف 1 ───
            Row(
              children: [
                Expanded(
                  child: AdaptiveButton(
                    label: 'الواجبات',
                    icon: AppIcons.homework,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.brandTealDeep,
                    fullWidth: true,
                    fontSize: 10,
                    onPressed: () => _openHomework(child),
                  ),
                ),
                SizedBox(width: AdaptiveHelper.spacing / 2),
                Expanded(
                  child: AdaptiveButton(
                    label: 'التقرير',
                    icon: AppIcons.report,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.brandTeal,
                    fullWidth: true,
                    fontSize: 10,
                    onPressed: () => _openWeeklyReport(child),
                  ),
                ),
                SizedBox(width: AdaptiveHelper.spacing / 2),
                Expanded(
                  child: AdaptiveButton(
                    label: 'الفريق',
                    icon: AppIcons.users,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.brandBlue,
                    fullWidth: true,
                    fontSize: 10,
                    onPressed: () => _openCareTeam(child),
                  ),
                ),
              ],
            ),
            SizedBox(height: AdaptiveHelper.spacing / 2),

            // ─── الصف 2 ───
            Row(
              children: [
                Expanded(
                  child: AdaptiveButton(
                    label: 'التقدّم',
                    icon: AppIcons.progress,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.green,
                    fullWidth: true,
                    onPressed: () => _openChildProgress(child),
                  ),
                ),
                SizedBox(width: AdaptiveHelper.spacing / 2),
                Expanded(
                  child: AdaptiveButton(
                    label: 'تعديل',
                    icon: AppIcons.edit,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.brandBlue,
                    fullWidth: true,
                    onPressed: () => _openEditChild(child),
                  ),
                ),
              ],
            ),
            SizedBox(height: AdaptiveHelper.spacing / 2),

            // ─── دروس لولي الأمر ───
            AdaptiveButton(
              label: 'دروس لولي الأمر',
              icon: AppIcons.parent,
              backgroundColor: AppColors.purple,
              onPressed: _openParentLessons,
            ),
            SizedBox(height: AdaptiveHelper.spacing / 2),

            // ─── طلب جلسة دعم تعليمي ───
            AdaptiveButton(
              label: 'طلب جلسة دعم تعليمي',
              icon: AppIcons.specialist,
              backgroundColor: AppColors.brandTeal,
              onPressed: () => _openLearningSupportRequest(child),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, Color color) {
    final size = AdaptiveHelper.avatarSize;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name.characters.first : '؟',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final (text, color, icon) = switch (status) {
      'evaluated' => ('تم التقييم', AppColors.brandTealDeep, AppIcons.check),
      'assigned' => ('تم التعيين', AppColors.brandBlue, AppIcons.verified),
      _ => ('قيد الانتظار', AppColors.green, AppIcons.clock),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: AdaptiveHelper.bodyFontSize - 4,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}