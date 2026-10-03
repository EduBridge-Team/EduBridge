// lib/screens/teacher_child_details/teacher_child_details_screen.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../model/homework_model.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../create_weekly_report_screen.dart';
import '../weekly_report_screen.dart';

part 'teacher_homework_tab.dart';
part 'teacher_homework_tab_widgets.dart';
part 'teacher_lessons_tab.dart';
part 'teacher_grade_sheet.dart';
part 'teacher_lessons_tab_view.dart';

class TeacherChildDetailsScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const TeacherChildDetailsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<TeacherChildDetailsScreen> createState() =>
      _TeacherChildDetailsScreenState();
}

class _TeacherChildDetailsScreenState extends State<TeacherChildDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index < 2) {
      if (_selectedTab == index) return;
      setState(() => _selectedTab = index);
      _tabController.animateTo(index);
      return;
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WeeklyReportScreen(
            childId: widget.childId,
            childName: widget.childName,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseDiscussionScreen(filterChildId: widget.childId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.childName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 3),
            Text(
              _selectedTab == 0 ? 'واجبات الطالب' : 'دروس الطالب',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateWeeklyReportScreen(
                          childId: widget.childId,
                          childName: widget.childName,
                        ),
                      ),
                    ),
                    icon: const Icon(AppIcons.edit, size: 18),
                    label: const Text('كتابة تقرير'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandTealDeep,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaseDiscussionScreen(
                          filterChildId: widget.childId,
                        ),
                      ),
                    ),
                    icon: const Icon(AppIcons.forum, size: 18),
                    label: const Text('دراسة الحالة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.purple,
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(
                        color: AppColors.purple.withValues(alpha: .45),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _HomeworkTab(
                  childId: widget.childId,
                  childName: widget.childName,
                ),
                _LessonsTab(
                  childId: widget.childId,
                  childName: widget.childName,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(AppIcons.homework),
            selectedIcon: Icon(Icons.assignment),
            label: 'الواجبات',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.lesson),
            selectedIcon: Icon(Icons.menu_book),
            label: 'الدروس',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.report),
            selectedIcon: Icon(Icons.description),
            label: 'التقارير',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.forum),
            selectedIcon: Icon(Icons.forum),
            label: 'الحالة',
          ),
        ],
      ),
    );
  }
}
