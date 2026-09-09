import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../screens/verify_identity_screen.dart';
import '../screens/teacher_screen.dart';
import '../screens/speclalist_screen.dart';
import '../screens/parent_screen.dart';
import '../screens/ministry_screen.dart';

Future<Widget> homeScreenForRole() async {
  final role = await ApiService.getRole();

  // 🛡️ استثناء الأدمن: لا يُطلب منه التوثيق، يدخل مباشرة
  if (role == 'admin') {
    return const HomeScreen();
  }

  // ✅ التعديل هنا: لا نوجه المعلم والمختص لشاشة التوثيق إجبارياً
  // بل نتركهم يدخلون لواجهتهم، والشاشة نفسها (كما في الصورة) تعرض بطاقة "وثّق هويتك" لتفعيل الصلاحيات

  switch (role) {
    case 'teacher':
      return const TeacherScreen();
    case 'specialist':
      return const SpecialistDashboardScreen();
    case 'parent':
      return const ParentScreen(parent: {});
    case 'ministry':
    case 'institution':
      return const MinistryScreen();
    default:
      return const HomeScreen();
  }
}