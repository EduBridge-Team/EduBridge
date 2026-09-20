// شاشة المعلم — الخطة + الواجبات + التقارير الأسبوعية + دراسة الحالة
import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/accessibility/profile_avatar_button.dart';
import 'add_certificate_sheet.dart';
import 'add_lesson_sheet.dart';
import 'case_discussion_screen.dart';
import 'create_homework_screen.dart';
import 'create_weekly_report_screen.dart';
import 'notifications_screen.dart';
import '../services/api_service.dart';
import '../services/approval_service.dart';
import '../services/notification_listener_service.dart';
import '../theme.dart';
import '../widgets/legal_links_button.dart';
import '../widgets/dashboard_menu.dart';
import '../utils/navigation.dart';
import 'weekly_report_screen.dart';
import 'welcome_screen.dart';
import 'educational_plan_sheet.dart';
import 'support_sheet.dart';
import 'child_lessons_screen.dart';
import 'child_progress_screen.dart';
import 'chats_screen.dart';
import 'verify_identity_screen.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  int _tabIndex = 0;

  List _children = [];
  List _lessons = [];
  List _types = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  Map? _viewingLesson;
  bool _adding = false;

  bool _verificationDialogShown = false;
  int? _currentUserId;

  // ✅ Switch "أطفالي فقط"
  bool _showOnlyMine = true;

  @override
  void initState() {
    super.initState();
    _loadData().then((_) => _checkAndShowVerificationDialog());
  }

  @override
  void dispose() {
    if (_adding || _viewingLesson != null) {
      inlineModalOpen.value = false;
    }
    super.dispose();
  }

  void _setAdding(bool value) {
    inlineModalOpen.value = value;
    setState(() => _adding = value);
  }

  void _setViewingLesson(Map? lesson) {
    inlineModalOpen.value = lesson != null;
    setState(() => _viewingLesson = lesson);
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _currentUserId = await ApiService.getUserId();

      final responses = await Future.wait([
        ApiService.authGet('/children'),
        ApiService.authGet('/lessons'),
        ApiService.authGet('/disability-types'),
      ]);

      final childrenData = jsonDecode(responses[0].body);
      final lessonsData = jsonDecode(responses[1].body);
      final typesData = jsonDecode(responses[2].body);

      if (responses[0].statusCode == 200 &&
          responses[1].statusCode == 200 &&
          responses[2].statusCode == 200) {
        final allChildren = childrenData['children'] ?? [];
        final myId = _currentUserId?.toString();

        // ✅ فلترة الأطفال: يظهر إذا كان المعلم مضمّناً
        final myChildren = allChildren.where((child) {
          // assigned_teacher_id (قديم)
          if (child['assigned_teacher_id']?.toString() == myId) return true;

          // assigned_teacher_ids (متعدد - جديد)
          final ids = child['assigned_teacher_ids'] as List?;
          if (ids != null && ids.map((e) => e.toString()).contains(myId)) {
            return true;
          }

          // teacher_ids (احتياط)
          final tIds = child['teacher_ids'] as List?;
          if (tIds != null && tIds.map((e) => e.toString()).contains(myId)) {
            return true;
          }

          return false;
        }).toList();

        if (!mounted) return;
        setState(() {
          _children = myChildren;
          _lessons = lessonsData['lessons'] ?? [];
          _types = typesData['disability_types'] ?? [];
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = childrenData['error'] ??
              lessonsData['error'] ??
              typesData['error'] ??
              'تعذّر جلب البيانات';
          _loading = false;
        });
      }
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
                  color: AppColors.teal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user,
                    size: 48, color: AppColors.teal),
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
                'عزيزي المعلم، يجب توثيق هويتك ورفع شهادتك العلمية للاستفادة من كامل صلاحيات التطبيق.',
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
                    backgroundColor: AppColors.teal,
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
            content: Text('⚠️ يرجى توثيق الهوية أولاً لتفعيل هذه الصلاحية'),
            backgroundColor: AppColors.teal,
          ),
        );
      }
      return false;
    }
    return true;
  }

  String? _typeName(int? id) {
    if (id == null) return null;
    for (final t in _types) {
      if (t['id'] == id) return (t['name'] ?? '').toString();
    }
    return null;
  }

  List get _filteredLessons {
    final q = _query.trim();
    if (q.isEmpty) return _lessons;
    return _lessons.where((l) {
      final title = (l['title'] ?? '').toString();
      final content = (l['content'] ?? '').toString();
      return title.contains(q) || content.contains(q);
    }).toList();
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  void _openChild(Map child) {
    final age = child['age'] is int ? child['age'] as int : 8;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildLessonsScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
          age: age,
          disabilityType: child['disability_type']?.toString(),
          parentPhone: child['parent_phone']?.toString(),
        ),
      ),
    ).then((_) => _loadData());
  }

  void _viewEducationalPlan(Map child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EducationalPlanSheet(child: child),
    );
  }

  void _viewChildProgress(Map child) {
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

  void _openCaseDiscussion(Map child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseDiscussionScreen(
          filterChildId: child['id'] as int,
        ),
      ),
    );
  }

  void _openCreateHomework() async {
    if (!await _checkVerification()) return;
    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateHomeworkScreen(children: _children),
      ),
    );
    if (result == true) _loadData();
  }

  void _createWeeklyReport(Map child) async {
    if (!await _checkVerification()) return;
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateWeeklyReportScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
        ),
      ),
    );

    if (result == true) _loadData();
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

  void _viewLesson(Map lesson) {
    _setViewingLesson(lesson);
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'evaluated':
        return 'تم التقييم ✓';
      case 'assigned':
        return 'تم التعيين ✓';
      default:
        return 'قيد الانتظار ⏳';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'evaluated':
        return AppColors.blue;
      case 'assigned':
        return AppColors.teal;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final inlineModalVisible = _adding || _viewingLesson != null;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(c),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (_tabIndex == 0)
                      Row(
                        children: [
                          Icon(Icons.people, size: 20, color: c.heading),
                          const SizedBox(width: 6),
                          Text(
                            'أطفالي فقط',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: c.heading,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    ValueListenableBuilder<int>(
                      valueListenable:
                          NotificationListenerService.instance.unreadCount,
                      builder: (context, count, _) {
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.notifications_outlined),
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
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
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
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _buildError()
                          : _buildBody(c),
                ),
              ),
            ],
          ),
          if (_viewingLesson != null) _buildViewModal(c),
          if (_adding) _buildAddModal(c),
        ],
      ),
      bottomNavigationBar: inlineModalVisible
          ? null
          : NavigationBar(
              selectedIndex: _tabIndex,
              onDestinationSelected: (i) => setState(() => _tabIndex = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'الأطفال',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'الدروس',
                ),
              ],
            ),
      floatingActionButton: _tabIndex == 1 && !inlineModalVisible
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
                      const Text(
                        'EduBridge',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  DashboardMenu(
                    actions: [
                      DashboardMenuAction(
                        id: 'case_discussion',
                        label: 'دراسات الحالة',
                        icon: Icons.forum,
                        onSelected: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CaseDiscussionScreen(),
                          ),
                        ),
                      ),
                      DashboardMenuAction(
                        id: 'create_homework',
                        label: 'إضافة واجب',
                        icon: Icons.assignment_add,
                        onSelected: _openCreateHomework,
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
                              builder: (_) => AddCertificateSheet(
                                onSaved: _loadData,
                              ),
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
                            builder: (_) => const ChatsScreen(),
                          ),
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
                  final name = snap.data ?? 'المعلم';
                  final childCount = _children.length;

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
                            ? 'لديك $childCount طفل${childCount != 1 ? 'اً' : ''} تحت مسؤوليتك'
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

              // ✅ Switch "أطفالي فقط" (في تبويب الأطفال)
              if (_tabIndex == 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.filter_alt,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'أطفالي فقط',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: _showOnlyMine,
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColors.green,
                          inactiveThumbColor: Colors.white70,
                          inactiveTrackColor:
                              Colors.white.withValues(alpha: 0.3),
                          onChanged: (v) =>
                              setState(() => _showOnlyMine = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                  style:
                      const TextStyle(fontSize: 16, color: Colors.red)),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 28),
                  label: const Text('إعادة المحاولة',
                      style: TextStyle(fontSize: 18)),
                  onPressed: _loadData,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(JisrColors c) {
    return _tabIndex == 0 ? _buildChildrenTab(c) : _buildLessonsTab(c);
  }

  Widget _buildChildrenTab(JisrColors c) {
    // في _loadData نفلتر بالفعل، لكن نعرض رسالة عندما لا يوجد
    final displayChildren = _children;

    if (displayChildren.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.people_outline, size: 72, color: c.muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'لا يوجد أطفال موزّعين عليك حالياً',
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
      itemBuilder: (context, i) {
        final child = displayChildren[i];
        final color = AppColors.kidPalette[i % AppColors.kidPalette.length];
        final name = (child['name'] ?? '').toString();
        final status = child['status'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: color,
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '🙂',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: c.heading,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (child['disability_type'] != null)
                      Text(
                        'الإعاقة: ${child['disability_type']}',
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    if (child['age'] != null)
                      Text(
                        'العمر: ${child['age']} سنة',
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => _openChild(child),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    // صف 1: الخطة + التقدّم
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 38),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            icon: const Icon(Icons.verified, size: 16),
                            label: const Text('الخطة'),
                            onPressed: () => _openApprovedPlan(child),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 38),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            icon: const Icon(Icons.insights, size: 16),
                            label: const Text('التقدّم'),
                            onPressed: () => _viewChildProgress(child),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // صف 2: اكتب تقرير + التقارير
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 38),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              backgroundColor: AppColors.teal,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.edit_note, size: 16),
                            label: const Text('اكتب تقرير'),
                            onPressed: () => _createWeeklyReport(child),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 38),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              foregroundColor: AppColors.tealDeep,
                            ),
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('التقارير'),
                            onPressed: () => _openWeeklyReport(child),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ✅ صف 3: دراسة الحالة
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          foregroundColor: AppColors.purple,
                          side: const BorderSide(
                              color: AppColors.purple, width: 1.5),
                        ),
                        icon: const Icon(Icons.forum, size: 18),
                        label: const Text(
                          'دراسة الحالة مع المختص',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _openCaseDiscussion(child),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openApprovedPlan(Map child) async {
    Map<String, dynamic>? plan;

    try {
      plan = await ApprovalService.getApprovedPlanForChild(child['id']);

      if (plan == null) {
        final serverPlans =
            await ApiService.getAllApprovals(status: 'approved');
        for (final p in serverPlans) {
          if (p['child_id'] == child['id']) {
            plan = Map<String, dynamic>.from(p);
            break;
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;

    if (plan == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue, size: 32),
              SizedBox(width: 8),
              Text('الخطة قيد المراجعة'),
            ],
          ),
          content: Text(
            'لم يتم اعتماد خطة "${child['name']}" من الوزارة بعد.\n\n'
            'يمكنك عرض الخطة الأولية من المختص.',
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
              ),
              icon: const Icon(Icons.school),
              label: const Text('الخطة الأولية'),
              onPressed: () {
                Navigator.pop(context);
                _viewEducationalPlan(child);
              },
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApprovedPlanSheet(plan: plan!),
    );
  }

  Widget _buildLessonsTab(JisrColors c) {
    final filtered = _filteredLessons;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            style: const TextStyle(fontSize: 17),
            decoration: const InputDecoration(
              hintText: 'ابحث عن درس...',
              prefixIcon: Icon(Icons.search),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    Icon(Icons.menu_book, size: 72, color: c.muted),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _lessons.isEmpty
                            ? 'لا توجد دروس بعد'
                            : 'لا نتائج مطابقة لبحثك',
                        style: TextStyle(fontSize: 18, color: c.muted),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _buildLessonCard(filtered[i], c),
                ),
        ),
      ],
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
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.heading,
          ),
        ),
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
              child: Text(
                targetBadge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: targetColor,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => _viewLesson(lesson),
      ),
    );
  }

  Widget _buildViewModal(JisrColors c) {
    final lesson = _viewingLesson!;
    final title = (lesson['title'] ?? '').toString();
    final content = (lesson['content'] ?? '').toString();
    final tag = _typeName(lesson['disability_type_id']);
    final videoUrl = lesson['video_url'];
    final audioUrl = lesson['audio_url'];
    final captionUrl = lesson['caption_url'];
    final signUrl = lesson['sign_language_url'];
    final audioDesc = lesson['audio_description'];

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => _setViewingLesson(null),
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
              ),
              constraints: const BoxConstraints(maxHeight: 600),
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
                          onPressed: () => _setViewingLesson(null),
                        ),
                      ],
                    ),
                    if (tag != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.greenDeep),
                        ),
                      ),
                    if (content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          content,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: c.body,
                          ),
                        ),
                      ),
                    if (videoUrl != null) ...[
                      const SizedBox(height: 8),
                      _mediaChip(Icons.video_library, '📹 فيديو مرفق',
                          AppColors.tealDeep, c.tintTeal),
                    ],
                    if (captionUrl != null) ...[
                      const SizedBox(height: 6),
                      _mediaChip(Icons.closed_caption, '📝 ملف ترجمات مرفق',
                          AppColors.pink,
                          AppColors.pink.withValues(alpha: 0.1)),
                    ],
                    if (signUrl != null) ...[
                      const SizedBox(height: 6),
                      _mediaChip(Icons.sign_language,
                          '🤟 فيديو لغة إشارة مرفق',
                          AppColors.purple,
                          AppColors.purple.withValues(alpha: 0.1)),
                    ],
                    if (audioDesc != null &&
                        audioDesc.toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.record_voice_over,
                                color: AppColors.orangeDeep, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '🔊 وصف صوتي: $audioDesc',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (audioUrl != null) ...[
                      const SizedBox(height: 6),
                      _mediaChip(Icons.audiotrack, '🎵 تسجيل صوتي مرفق',
                          AppColors.greenDeep, c.tintGreen),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mediaChip(
    IconData icon,
    String label,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
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
//  شاشة عرض الخطة المعتمدة
// ═══════════════════════════════════════════════════════════
class _ApprovedPlanSheet extends StatelessWidget {
  final Map plan;

  const _ApprovedPlanSheet({required this.plan});

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الخطة المعتمدة - ${plan['child_name'] ?? ''}',
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم اعتماد هذه الخطة من الوزارة',
                      style: TextStyle(fontSize: 13, color: c.onTint),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _section('📚 الخطة التعليمية', plan['educational_plan'], c),
            _section(
                '🧠 التقييم المعرفي', plan['cognitive_assessment'], c),
            _section('🏃 التقييم الحركي', plan['motor_assessment'], c),
            _section(
                '💚 التقييم العاطفي', plan['emotional_assessment'], c),
            _section(
                '🤝 التقييم الاجتماعي', plan['social_assessment'], c),
            _section('📝 التوصيات', plan['recommendations'], c),
            if (plan['teaching_methods'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                '🎓 طرق التدريس المقترحة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (plan['teaching_methods'] as List? ?? [])
                    .map((m) => Chip(
                          label: Text(m.toString()),
                          backgroundColor: c.tintGreen,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String label, dynamic value, JisrColors c) {
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(value.toString(),
              style: TextStyle(fontSize: 14, height: 1.5, color: c.body)),
        ],
      ),
    );
  }
}