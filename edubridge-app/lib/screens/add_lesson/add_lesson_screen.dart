import 'package:flutter/material.dart';
import '../../app_icons.dart';
import 'add_lesson_sheet.dart';
import '../teacher/teacher_screen.dart';

class AddLessonScreen extends StatelessWidget {
  final List types;

  const AddLessonScreen({
    super.key,
    required this.types,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AddLessonSheet(
        types: types,
        fullScreen: true,
        onClose: () => Navigator.pop(context),
        onCreated: (lesson) => Navigator.pop(context, lesson),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
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
