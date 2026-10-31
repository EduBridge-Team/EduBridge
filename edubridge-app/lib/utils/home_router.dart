import 'dart:async';
import '../services/schools/school_management_repository.dart';
import '../screens/school_management/school_management_screen.dart';
import 'package:flutter/material.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/ministry/ministry_screen.dart';
import '../screens/specialist/specialist_screen.dart';
import '../screens/teacher/teacher_screen.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../screens/parent_screen.dart';
import '../screens/institution_screen.dart';
import '../screens/enrollment/school_dashboard_screen.dart';

Future<Widget> homeScreenForRole() async {
  final role = await ApiService.getRole();

  // 🛡️ استثناء الأدمن: لا يُطلب منه التوثيق، يدخل مباشرة
  if (role == 'admin') {
    return const AdminScreen(admin: {'role': 'admin'});
  }

  // ✅ التعديل هنا: لا نوجه المعلم والمختص لشاشة التوثيق إجبارياً
  // بل نتركهم يدخلون لواجهتهم، والشاشة نفسها (كما في الصورة) تعرض بطاقة "وثّق هويتك" لتفعيل الصلاحيات

  if (role != 'school' && await ApiService.getToken() != null) {
    try {
      await SchoolManagementRepository().context().timeout(const Duration(seconds: 3));
      return SchoolManagementScreen(personalHome: () => personalHomeForRole(role));
    } on Exception { /* An assignment never replaces the global personal role. */ }
  }
  return personalHomeForRole(role);
}

Widget personalHomeForRole(String? role) {
  switch (role) {
    case 'teacher':
      return const TeacherScreen();
    case 'specialist':
      return const SpecialistDashboardScreen();
    case 'parent':
      return const ParentScreen();
    case 'ministry':
      return const MinistryScreen();
    case 'school':
      return const SchoolDashboardScreen();
    case 'institution':
      return const InstitutionScreen();
    default:
      return const HomeScreen();
  }
}
