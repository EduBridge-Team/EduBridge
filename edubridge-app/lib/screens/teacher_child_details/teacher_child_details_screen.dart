// lib/screens/teacher_child_details/teacher_child_details_screen.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../model/homework_model.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../create_weekly_report_screen.dart';
import '../teacher/teacher_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
        title: Text(
          widget.childName,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          tabs: const [
            Tab(icon: Icon(AppIcons.homework, size: 22), text: 'الواجبات'),
            Tab(icon: Icon(AppIcons.lesson, size: 22), text: 'الدروس'),
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
        selectedIndex: 0,
        onDestinationSelected: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherScreen(initialTab: index),
            ),
            (route) => false,
          );
        },
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
    );
  }
}