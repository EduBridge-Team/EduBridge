// lib/screens/teacher_child_details/teacher_child_details_screen.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../model/homework_model.dart';
import '../../model/weekly_report_model.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../add_lesson/add_lesson_screen.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../create_homework_screen.dart';
import '../create_weekly_report_screen.dart';
import '../weekly_report_screen.dart';

part 'teacher_homework_tab.dart';
part 'teacher_homework_tab_widgets.dart';
part 'teacher_lessons_tab.dart';
part 'teacher_grade_sheet.dart';
part 'teacher_lessons_tab_view.dart';
part 'teacher_reports_tab.dart';

class TeacherChildDetailsScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final int initialTab;
  final bool showBottomNavigation;

  const TeacherChildDetailsScreen({
    super.key,
    required this.childId,
    required this.childName,
    this.initialTab = 0,
    this.showBottomNavigation = true,
  });

  @override
  State<TeacherChildDetailsScreen> createState() =>
      _TeacherChildDetailsScreenState();
}

class _TeacherChildDetailsScreenState extends State<TeacherChildDetailsScreen> {
  late int _selectedTab;

  static const _tabTitles = [
    'واجبات الطالب',
    'دروس الطالب',
    'تقارير الطالب',
    'حالة الطالب',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 3).toInt();
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
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
              _tabTitles[_selectedTab],
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _HomeworkTab(
            childId: widget.childId,
            childName: widget.childName,
          ),
          _LessonsTab(
            childId: widget.childId,
            childName: widget.childName,
          ),
          _TeacherReportsTab(
            childId: widget.childId,
            childName: widget.childName,
          ),
          CaseDiscussionScreen(
            filterChildId: widget.childId,
            embedded: true,
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNavigation
          ? NavigationBar(
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
            )
          : null,
    );
  }
}
