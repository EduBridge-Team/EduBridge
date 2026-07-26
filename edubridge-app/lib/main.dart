// نقطة تشغيل التطبيق
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const EduBridgeApp());
}

class EduBridgeApp extends StatelessWidget {
  const EduBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduBridge — جسر تعليمي',
      debugShowCheckedModeBanner: false,

      // اتجاه الواجهة من اليمين لليسار (عربي)
      locale: const Locale('ar'),

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D6B),
        // نصوص أكبر قليلاً لسهولة القراءة (accessibility)
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),

      // تغليف كامل التطبيق باتجاه RTL
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),

      // نقرّر شاشة البداية حسب وجود توكن محفوظ
      home: FutureBuilder<String?>(
        future: ApiService.getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final loggedIn = snapshot.data != null;
          return loggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
