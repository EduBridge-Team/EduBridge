import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../screens/verify_identity_screen.dart';
import '../screens/teacher_screen.dart';
import '../screens/speclalist_screen.dart';
import '../screens/parent_screen.dart';
import '../screens/ministry_screen.dart';
import '../widgets/verification_access_gate.dart';

Future<Widget> homeScreenForRole() async {
  final role = await ApiService.getRole();

  // 🛡️ استثناء الأدمن: لا يُطلب منه التوثيق، يدخل مباشرة
  if (role == 'admin') {
    return const HomeScreen();
  }

  

  switch (role) {
    case 'teacher':
      return const VerificationAccessGate(child: TeacherScreen());
    case 'specialist':
      return const VerificationAccessGate(
        child: SpecialistDashboardScreen(),
      );
    case 'parent':
      return const ParentScreen(parent: {});
    case 'ministry':
      return const MinistryScreen();
    default:
      return const HomeScreen();
  }
}
