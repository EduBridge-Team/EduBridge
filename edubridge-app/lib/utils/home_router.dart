// توجيه الشاشة الرئيسية حسب دور المستخدم
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../screens/teacher_dashboard_screen.dart';
import '../screens/specialist_dashboard_screen.dart';

Future<Widget> homeScreenForRole() async {
  final role = await ApiService.getRole();
  switch (role) {
    case 'teacher':
      return const TeacherDashboardScreen();
    case 'specialist':
      return const SpecialistDashboardScreen();
    default:
      return const HomeScreen();
  }
}
