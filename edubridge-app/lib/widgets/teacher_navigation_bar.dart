import '../l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../app_icons.dart';
import '../screens/teacher/teacher_screen.dart';
import '../screens/specialist/specialist_screen.dart';
import '../services/api_service.dart';

/// Keeps top-level teacher and specialist destinations available on shared screens.
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
        final role = snapshot.data;
        if (!['teacher', 'specialist'].contains(role)) {
          return const SizedBox.shrink();
        }
        final destinations = role == 'teacher'
            ? [
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: context.l10n.children,
                ),
                NavigationDestination(
                  icon: Icon(AppIcons.lesson),
                  selectedIcon: Icon(Icons.menu_book),
                  label: context.l10n.lessons,
                ),
                NavigationDestination(
                  icon: Icon(AppIcons.homework),
                  selectedIcon: Icon(Icons.assignment),
                  label: context.l10n.homework,
                ),
              ]
            : [
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: context.l10n.students,
                ),
                NavigationDestination(
                  icon: Icon(AppIcons.lesson),
                  selectedIcon: Icon(Icons.menu_book),
                  label: context.l10n.lessons,
                ),
              ];

        return NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (index) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute<void>(
                builder: (_) => role == 'specialist'
                    ? SpecialistDashboardScreen(initialTab: index)
                    : TeacherScreen(initialTab: index),
              ),
              (route) => false,
            );
          },
          destinations: destinations,
        );
      },
    );
  }
}
