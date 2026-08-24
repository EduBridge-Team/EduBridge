// توجيه الشاشة الرئيسية حسب دور المستخدم
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../screens/teacher_screen.dart';
import '../screens/speclalist_screen.dart';
import '../screens/parent_screen.dart'; // سننشئ هذه الشاشة

Future<Widget> homeScreenForRole() async {
  final role = await ApiService.getRole();
  switch (role) {
    case 'teacher':
      return const TeacherScreen();
    case 'specialist':
      return const SpecialistDashboardScreen();
    case 'parent':
      return const ParentScreen(parent: {},); // شاشة ولي الأمر الجديدة
    default:
      return const HomeScreen();
  }
}