import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/tts_service.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme.dart';
import 'utils/home_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSavedThemeMode();
  await TtsService.init();
  runApp(const EduBridgeApp());
}

Future<Widget> _initialScreen() async {
  final token = await ApiService.getToken();
  if (token == null) return const WelcomeScreen();
  return homeScreenForRole();
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

        // شاشة البداية (Splash) ثم تنتقل إلى «/home»
        home: const SplashScreen(),

        // «/home» تقرّر الوجهة حسب وجود توكن محفوظ ودور المستخدم
        routes: {
          '/home': (context) => const _HomeGate(),
        },
      ),
    );
  }
}

/// بوابة الشاشة الرئيسية — تختار الوجهة حسب التوكن ودور المستخدم
class _HomeGate extends StatelessWidget {
  const _HomeGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data ?? const WelcomeScreen();
      },
    );
  }
}
