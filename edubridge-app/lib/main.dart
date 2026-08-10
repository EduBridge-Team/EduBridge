// نقطة تشغيل التطبيق
import 'package:edubridge_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // استرجاع وضع الثيم المحفوظ (فاتح/ليلي) قبل التشغيل
  await loadSavedThemeMode();
  runApp(const EduBridgeApp());
}

class EduBridgeApp extends StatelessWidget {
  const EduBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // نستمع لتغيّر وضع الثيم حتى يتبدّل التطبيق فوراً عند الضغط على 🌙
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: jisrThemeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'EduBridge — جسر تعليمي',
        debugShowCheckedModeBanner: false,

        // اتجاه الواجهة من اليمين لليسار (عربي)
        locale: const Locale('ar'),

        // ثيما هوية «جسر»: فاتح وليلي — انظر theme.dart
        theme: buildJisrTheme(),
        darkTheme: buildJisrDarkTheme(),
        themeMode: mode,

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
            return loggedIn ?  HomeScreen() : const WelcomeScreen();
          },
        ),
      ),
    );
  }
}
