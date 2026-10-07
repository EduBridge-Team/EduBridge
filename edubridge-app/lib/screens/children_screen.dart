import '../utils/presentation_text.dart';
// lib/screens/children_screen.dart
import 'package:flutter/material.dart';

import '../app_icons.dart';
import '../services/api_service.dart';
import '../services/paged_list_controller.dart';
import '../widgets/list_pagination.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/listen_button.dart';
import '../widgets/speakable.dart';
import 'child_lessons/child_lessons_screen.dart';
import 'child_progress_screen.dart';
import 'weekly_report_screen.dart';
import 'child_homework/child_homework_screen.dart';
import 'teacher_child_details/teacher_child_details_screen.dart';
import 'specialist/specialist_child_profile_screen.dart';
import '../widgets/teacher_navigation_bar.dart';

class ChildrenScreen extends StatefulWidget {
  String? get destinationLabel => switch (destination) {
    'weekly-reports' => 'التقدم الأسبوعي', 'homeworks' => 'الواجبات', _ => null,
  };
  final String? destination;
  final bool forProgress;
  const ChildrenScreen({super.key, this.forProgress = false, this.destination});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  String? _role;
  List _children = [];
  late final PagedListController _pages;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pages = PagedListController((page, query) => ApiService.getChildrenPage(page: page, query: query));
    _pages.addListener(_syncPage);
    _loadChildren();
  }

  @override
  void dispose() {
    _pages.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  void _syncPage() {
    if (!mounted) return;
    setState(() {
      _children = _pages.items;
      _loading = _pages.loading;
      _error = _pages.error;
    });
  }

  Future<void> _loadChildren() async {
    final role = await ApiService.getRole();
    if (!mounted) return;
    setState(() => _role = role);
    await _pages.load();
  }

  Future<void> _refreshChildren() async {
    final role = await ApiService.getRole();
    if (!mounted) return;
    setState(() => _role = role);
    await _pages.refresh();
  }

  void _openChild(Map child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => widget.destination == 'weekly-reports'
            ? WeeklyReportScreen(childId: child['id'], childName: child['name'] ?? '')
            : widget.destination == 'homeworks'
            ? ChildHomeworkScreen(childId: child['id'], childName: child['name'] ?? '')
            : widget.forProgress
            ? ChildProgressScreen(childId: child['id'], childName: child['name'] ?? '')
            : _role == 'teacher'
            ? TeacherChildDetailsScreen(childId: child['id'], childName: child['name'] ?? '')
            : _role == 'specialist'
            ? SpecialistChildProfileScreen(child: Map<String, dynamic>.from(child))
            : ChildLessonsScreen(childId: child['id'], childName: child['name'] ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(
        title: widget.destinationLabel != null ? 'اختر طالباً لعرض ${widget.destinationLabel}' : widget.forProgress ? 'اختر طفلاً لعرض تقدّمه' : 'الأطفال',
        actions: const [ListenButton()],
      ),
      bottomNavigationBar: const TeacherNavigationBar(),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(
          decoration: const InputDecoration(hintText: 'ابحث عن طفل أو معلّم...', prefixIcon: Icon(AppIcons.search)),
          onChanged: _pages.search,
        )),
        Expanded(child: RefreshIndicator(onRefresh: _refreshChildren, child: _buildBody())),
        ListPagination(controller: _pages),
      ]),
    );
  }

  Widget _buildBody() {
    final c = JisrColors.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(AppIcons.error, size: 58, color: AppColors.red),
          const SizedBox(height: 14),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton.icon(
              onPressed: _loadChildren,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
    }

    if (_children.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 110),
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: c.tintTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.child_care_rounded,
                size: 40,
                color: AppColors.brandBlue,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _pages.query.trim().isEmpty ? 'لا يوجد أطفال بعد' : 'لا نتائج مطابقة لبحثك',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: c.heading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'سيظهر الأطفال المرتبطون بحسابك هنا.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: c.muted),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      itemCount: _children.length,
      itemBuilder: (context, i) {
        final child = _children[i];
        final color = AppColors.kidPalette[i % AppColors.kidPalette.length];
        final name = (child['name'] ?? '').toString();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Speakable(
            text: name,
            onTap: () => _openChild(child),
            child: Material(
              color: c.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: c.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openChild(child),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(19),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          PresentationText.initial(name, fallback: '؟'),
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: c.heading,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.forProgress
                                  ? 'عرض التقدّم والإنجازات'
                                  : widget.destinationLabel ?? (['teacher', 'specialist'].contains(_role) ? 'عرض ملف الطالب' : 'عرض الدروس والأنشطة'),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c.tintTeal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 19,
                          color: AppColors.brandBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
