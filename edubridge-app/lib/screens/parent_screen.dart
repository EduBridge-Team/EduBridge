// screens/parent_screen.dart
// لوحة ولي الأمر — مع كل ميزات التكييف + دروس لولي الأمر
import 'dart:convert';
import 'package:flutter/material.dart';
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
import 'notifications_screen.dart';
import 'support_sheet.dart';
import 'child_lessons_screen.dart';
import 'child_progress_screen.dart';
import 'add_child_screen.dart';
import 'edit_child_screen.dart';
import 'children_accessibility_overview_screen.dart';
import 'child_homework_screen.dart';
import 'weekly_report_screen.dart';
import 'care_team_screen.dart';
import 'create_therapy_request_screen.dart';
import 'add_certificate_sheet.dart';
import 'chats_screen.dart';
import 'parent_lessons_screen.dart'; // ✅ جديد

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

  // ═══════════════════════════════════════════════════════════
  //  التنقل بين الشاشات
  // ═══════════════════════════════════════════════════════════

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

  Future<void> _openTherapyRequest(Map child) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTherapyRequestScreen(
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

  // ✅ جديد: فتح شاشة دروس ولي الأمر
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
          icon: const Icon(Icons.add),
          label: const Text('إضافة طفل'),
          backgroundColor: AppColors.teal,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.headerGradient,
        ),
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
              icon: Icons.notifications_outlined,
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
              icon: Icons.family_restroom,
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
              icon: Icons.headset_mic,
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
              icon: Icons.chat_outlined,
              onSelected: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatsScreen()),
              ),
            ),
            DashboardMenuAction(
              id: 'certificate',
              label: 'إضافة شهادة',
              icon: Icons.workspace_premium_outlined,
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
              icon: Icons.privacy_tip_outlined,
              onSelected: () => const LegalLinksButton().show(context),
            ),
            DashboardMenuAction(
              id: 'logout',
              label: 'تسجيل الخروج',
              icon: Icons.logout,
              destructive: true,
              onSelected: () async {
                await ApiService.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
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
                    'مرحباً $name 👋',
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
              Icons.error_outline,
              size: AdaptiveHelper.iconSize * 2,
              color: Colors.red,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            AdaptiveText(
              _error!,
              textAlign: TextAlign.center,
              color: Colors.red,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            AdaptiveButton(
              label: 'إعادة المحاولة',
              icon: Icons.refresh,
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
              color: Colors.grey,
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
            // ═══ الرأس: الأفاتار + المعلومات + الحالة ═══
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
                          color: AppColors.tealDeep,
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),

            SizedBox(height: AdaptiveHelper.spacing),

            // ═══ الصف 1: الواجبات + التقرير + الفريق ═══
            Row(
              children: [
                Expanded(
                  child: AdaptiveButton(
                    label: 'الواجبات',
                    icon: Icons.assignment,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.orange,
                    fullWidth: true,
                    fontSize: 10,
                    onPressed: () => _openHomework(child),
                  ),
                ),
                SizedBox(width: AdaptiveHelper.spacing / 2),
                Expanded(
                  child: AdaptiveButton(
                    label: 'التقرير',
                    icon: Icons.bar_chart,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.teal,
                    fullWidth: true,
                    fontSize: 10,
                    onPressed: () => _openWeeklyReport(child),
                  ),
                ),
                SizedBox(width: AdaptiveHelper.spacing / 2),
                Expanded(
                  child: AdaptiveButton(
                    label: 'الفريق',
                    icon: Icons.groups,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.pink,
                    fullWidth: true,
                    fontSize: 10,
                    onPressed: () => _openCareTeam(child),
                  ),
                ),
              ],
            ),
            SizedBox(height: AdaptiveHelper.spacing / 2),

            // ═══ الصف 2: التقدّم + تعديل ═══
            Row(
              children: [
                Expanded(
                  child: AdaptiveButton(
                    label: 'التقدّم',
                    icon: Icons.insights,
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
                    icon: Icons.edit,
                    style: AdaptiveButtonStyle.outlined,
                    backgroundColor: AppColors.navy,
                    fullWidth: true,
                    onPressed: () => _openEditChild(child),
                  ),
                ),
              ],
            ),
            SizedBox(height: AdaptiveHelper.spacing / 2),

            // ═══ الصف 3: دروس لولي الأمر (جديد) ═══
            AdaptiveButton(
              label: 'دروس لولي الأمر',
              icon: Icons.family_restroom,
              backgroundColor: AppColors.purple,
              onPressed: _openParentLessons,
            ),
            SizedBox(height: AdaptiveHelper.spacing / 2),

            // ═══ الصف 4: طلب جلسة نفسية ═══
            AdaptiveButton(
              label: 'طلب جلسة نفسية',
              icon: Icons.psychology,
              backgroundColor: AppColors.purple,
              onPressed: () => _openTherapyRequest(child),
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
        name.isNotEmpty ? name.characters.first : '🙂',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final (text, color) = switch (status) {
      'evaluated' => ('تم التقييم ✓', AppColors.green),
      'assigned' => ('تم التعيين ✓', AppColors.teal),
      _ => ('قيد الانتظار', AppColors.orange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AdaptiveHelper.bodyFontSize - 4,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}