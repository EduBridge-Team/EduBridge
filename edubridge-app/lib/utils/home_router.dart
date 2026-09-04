import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../screens/verify_identity_screen.dart';
import '../screens/teacher_screen.dart';
import '../screens/speclalist_screen.dart';
import '../screens/parent_screen.dart';

Future<Widget> homeScreenForRole() async {
  final role = await ApiService.getRole();

  // 🛡️ استثناء الأدمن: لا يُطلب منه التوثيق، يدخل مباشرة
  if (role == 'admin') {
    return const HomeScreen();
  }

  // التحقق من التوثيق لباقي الأدوار
  final verificationStatus = await ApiService.getVerificationStatus();
  if (verificationStatus != 'approved') {
    return const VerifyIdentityScreen();
  }

  switch (role) {
    case 'teacher':
      return const TeacherScreen();
    case 'specialist':
      return const SpecialistDashboardScreen();
    case 'parent':
      return const ParentScreen(parent: {});
    default:
      return const HomeScreen();
  }
}