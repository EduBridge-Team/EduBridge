// توجيه الشاشة الرئيسية حسب دور المستخدم
import 'package:edubridge_app/screens/speclalist_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../screens/teacher_screen.dart';

Future<Widget> homeScreenForRole() async {
  final role = await ApiService.getRole();
  switch (role) {
    case 'teacher':
      return const TeacherScreen();
    case 'specialist':
      return const SpecialistDashboardScreen();

    default:
      return const HomeScreen();
  }
}
