// توجيه الشاشة الرئيسية حسب دور المستخدم
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../screens/teacher_screen.dart';

Future<Widget> homeScreenForRole() async {
  final role = await ApiService.getRole();
  switch (role) {
    case 'teacher':
      return const TeacherScreen();
    default:
      return const HomeScreen();
  }
}
