// lib/screens/teacher_child_details/teacher_child_details_screen.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../model/homework_model.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

part 'teacher_homework_tab.dart';
part 'teacher_homework_tab_widgets.dart';
part 'teacher_lessons_tab.dart';
part 'teacher_grade_sheet.dart';

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
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
        title: Text(
          widget.childName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
              const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(AppIcons.homework, size: 22), text: 'الواجبات'),
            Tab(icon: Icon(AppIcons.lesson, size: 22), text: 'الدروس'),
          ],
        ),
      ),
      body: TabBarView(
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
    );
  }
}