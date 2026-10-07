import '../../utils/presentation_text.dart';
// lib/screens/teacher/teacher_screen.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../model/homework_model.dart';
import '../../services/approval_service.dart';
import '../../widgets/accessibility/profile_avatar_button.dart';
import '../../widgets/legal_links_button.dart';
import '../../widgets/dashboard_menu.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../utils/navigation.dart';
import '../add_lesson/add_lesson_screen.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../chats_screen.dart';
import '../child_progress_screen.dart';
import '../create_homework_screen.dart';
import '../educational_plan_sheet.dart';
import '../notifications_screen.dart';
import '../support_sheet.dart';
import '../teacher_child_details/teacher_child_details_screen.dart' show TeacherChildDetailsScreen;
import 'teacher_child_profile_screen.dart';
import '../verify_identity/verify_identity_screen.dart';
import '../login_screen.dart';

part 'teacher_children_tab.dart';
part 'teacher_lessons_tab.dart';
part 'teacher_homeworks_tab.dart';
part 'teacher_plan_sheet.dart';
part 'teacher_shared_widgets.dart';
part 'teacher_actions.dart';
part 'teacher_child_card_view.dart';

class TeacherScreen extends StatefulWidget {
  final int initialTab;

  const TeacherScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  late int _tabIndex;
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

  void _refreshTeacherState(VoidCallback callback) => setState(callback);

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab < 0
        ? 0
        : (widget.initialTab > 2 ? 2 : widget.initialTab);
    _loadData().then((_) => _checkAndShowVerificationDialog());
  }

  @override
  void dispose() {
    if (_adding || _viewingLesson != null) {
      inlineModalOpen.value = false;
    }
    super.dispose();
  }

  void _setViewingLesson(Map? lesson) {
    inlineModalOpen.value = lesson != null;
    setState(() => _viewingLesson = lesson);
  }

  Future<void> _refreshData() => _loadData(showLoader: false);

  Future<void> _loadData({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (_error != null) {
      setState(() => _error = null);
    }

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
        final myChildren = List<dynamic>.from(childrenData['children'] ?? []);

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

  Widget _currentPrimaryTab(BuildContext context, JisrColors c) {
    if (_tabIndex == 0) {
      return _buildChildrenTab(context, c, _children, _query,
          (v) => setState(() => _query = v), _typeName, _loadData);
    }
    return _buildLessonsTab(context, c, _lessons, _types, _query,
        (v) => setState(() => _query = v),
        (lesson) => _setViewingLesson(lesson));
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

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
                onVerify: _checkVerification,
                onLoadData: _loadData,
              ),
              Expanded(
                child: _tabIndex == 2
                    ? _TeacherHomeworksTab(children: _children)
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _error != null
                                ? _buildTeacherError(_error!, _loadData)
                                : _currentPrimaryTab(context, c),
                      ),
              ),
            ],
          ),
          if (_viewingLesson != null)
            _buildLessonViewModal(context, c, _viewingLesson!, _typeName,
                () => _setViewingLesson(null)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
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
          NavigationDestination(
            icon: Icon(AppIcons.homework),
            selectedIcon: Icon(Icons.assignment),
            label: 'الواجبات',
          ),
        ],
      ),
      floatingActionButton: _tabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final lesson = await Navigator.push<Map>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddLessonScreen(types: _types),
                  ),
                );
                if (!mounted || lesson == null) return;
                setState(() => _lessons = [lesson, ..._lessons]);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إضافة الدرس بنجاح'),
                    backgroundColor: AppColors.green,
                  ),
                );
              },
              icon: const Icon(AppIcons.add),
              label: const Text(
                'إضافة درس',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
