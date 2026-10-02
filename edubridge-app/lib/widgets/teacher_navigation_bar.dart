import 'package:flutter/material.dart';

import '../app_icons.dart';
import '../screens/teacher/teacher_screen.dart';
import '../screens/specialist/specialist_screen.dart';
import '../services/api_service.dart';

/// Keeps the teacher's destinations available on shared detail screens.
class TeacherNavigationBar extends StatefulWidget {
  const TeacherNavigationBar({super.key});

  @override
  State<TeacherNavigationBar> createState() => _TeacherNavigationBarState();
}

class _TeacherNavigationBarState extends State<TeacherNavigationBar> {
  late final Future<String?> _role = ApiService.getRole();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _role,
      builder: (context, snapshot) {
        if (!['teacher', 'specialist'].contains(snapshot.data)) return const SizedBox.shrink();
        return NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (index) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute<void>(
                builder: (_) => snapshot.data == 'specialist' ? SpecialistDashboardScreen(initialTab: index) : TeacherScreen(initialTab: index),
              ),
              (route) => false,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'الطلاب',
            ),
            NavigationDestination(
              icon: Icon(AppIcons.lesson),
              selectedIcon: Icon(Icons.menu_book),
              label: 'الدروس',
            ),
          ],
        );
      },
    );
  }
}
