import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../screens/teacher_screen.dart';
import '../screens/speclalist_screen.dart';
import '../screens/parent_screen.dart';
import '../screens/ministry_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/institution_screen.dart';

Future<Widget> homeScreenForRole() async {
  final role = await ApiService.getRole();

  // 🛡️ استثناء الأدمن: لا يُطلب منه التوثيق، يدخل مباشرة
  if (role == 'admin') {
    return const AdminScreen(admin: {});
  }

  // ✅ التعديل هنا: لا نوجه المعلم والمختص لشاشة التوثيق إجبارياً
  // بل نتركهم يدخلون لواجهتهم، والشاشة نفسها (كما في الصورة) تعرض بطاقة "وثّق هويتك" لتفعيل الصلاحيات

  switch (role) {
    case 'teacher':
      return const TeacherScreen();
    case 'specialist':
      return const SpecialistDashboardScreen();
    case 'parent':
      return const ParentScreen();
    case 'ministry':
      return const MinistryScreen();
    case 'institution':
      return const InstitutionScreen();
    default:
      return const HomeScreen();
  }
}
