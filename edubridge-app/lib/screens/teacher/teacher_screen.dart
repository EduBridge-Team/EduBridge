// lib/screens/teacher/teacher_screen.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/approval_service.dart';
import '../../widgets/accessibility/profile_avatar_button.dart';
import '../../widgets/legal_links_button.dart';
import '../../widgets/dashboard_menu.dart';
import '../../services/api_service.dart';
import '../../services/notification_listener_service.dart';
import '../../theme.dart';
import '../../utils/navigation.dart';
import '../add_certificate_sheet.dart';
import '../add_lesson/add_lesson_sheet.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../chats_screen.dart';
import '../child_progress_screen.dart';
import '../create_homework_screen.dart';
import '../create_weekly_report_screen.dart';
import '../educational_plan_sheet.dart';
import '../notifications_screen.dart';
import '../support_sheet.dart';
import '../teacher_child_details/teacher_child_details_screen.dart' show TeacherChildDetailsScreen;
import '../verify_identity/verify_identity_screen.dart';
import '../weekly_report_screen.dart';
import '../welcome_screen.dart';

part 'teacher_children_tab.dart';
part 'teacher_lessons_tab.dart';
part 'teacher_plan_sheet.dart';
part 'teacher_shared_widgets.dart';

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

      final childrenData = ApiService.decodeMap(responses[0].body);
      final lessonsData = ApiService.decodeMap(responses[1].body);
      final typesData = ApiService.decodeMap(responses[2].body);

      if (responses[0].statusCode == 200 &&
          responses[1].statusCode == 200 &&
          responses[2].statusCode == 200) {
        final allChildren = childrenData['children'] ?? [];
        final myId = _currentUserId?.toString();

        final myChildren = allChildren.where((child) {
          if (child['assigned_teacher_id']?.toString() == myId) return true;
          final ids = child['assigned_teacher_ids'] as List?;
          if (ids != null && ids.map((e) => e.toString()).contains(myId)) return true;
          final tIds = child['teacher_ids'] as List?;
          if (tIds != null && tIds.map((e) => e.toString()).contains(myId)) return true;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.verified,
                    size: 48, color: AppColors.brandTeal),
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
                    backgroundColor: AppColors.brandTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(AppIcons.verified, size: 22),
                  label: const Text('توثيق الهوية والشهادة',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  onPressed: () async {
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
            content: Text('يرجى توثيق الهوية أولاً لتفعيل هذه الصلاحية'),
            backgroundColor: AppColors.brandTeal,
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
        MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  Future<void> _openCreateHomework() async {
    if (!await _checkVerification()) return;
    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateHomeworkScreen(children: _children)),
    );
    if (result == true) _loadData();
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
              _buildTeacherHeader(
                context: context,
                c: c,
                tabIndex: _tabIndex,
                childrenCount: _children.length,
                onLogout: _logout,
                onOpenHomework: _openCreateHomework,
                onVerify: _checkVerification,
                onLoadData: _loadData,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Spacer(),
                    ValueListenableBuilder<int>(
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
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _buildTeacherError(_error!, _loadData)
                          : (_tabIndex == 0
                              ? _buildChildrenTab(context, c, _children, _query,
                                  (v) => setState(() => _query = v), _typeName, _loadData)
                              : _buildLessonsTab(context, c, _lessons, _types, _query,
                                  (v) => setState(() => _query = v),
                                  (lesson) => _setViewingLesson(lesson))),
                ),
              ),
            ],
          ),
          if (_viewingLesson != null)
            _buildLessonViewModal(context, c, _viewingLesson!, _typeName,
                () => _setViewingLesson(null)),
          if (_adding)
            Positioned.fill(
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
                      backgroundColor: AppColors.green,
                    ),
                  );
                },
              ),
            ),
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
                  icon: Icon(AppIcons.lesson),
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
              icon: const Icon(AppIcons.add),
              label: const Text('إضافة درس'),
              backgroundColor: AppColors.green,
            )
          : null,
    );
  }
}