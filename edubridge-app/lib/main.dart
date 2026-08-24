
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/api_service.dart';
import 'services/tts_service.dart';
import 'screens/welcome_screen.dart';
import 'theme.dart';
import 'utils/home_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تحميل وضع الثيم (فاتح/ليلي) من التخزين المحلي
  await loadSavedThemeMode();
  // تهيئة خدمة النطق الصوتي (مرة واحدة عند بدء التطبيق)
  await TtsService.init();

  runApp(const ProviderScope(child: EduBridgeApp()));
}

/// تطبيق جسر التعليمي
class EduBridgeApp extends StatelessWidget {
  const EduBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // مراقبة تغير وضع الثيم لتحديث الواجهة فوراً
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: jisrThemeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'EduBridge — جسر تعليمي',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        theme: buildJisrTheme(),
        darkTheme: buildJisrDarkTheme(),
        themeMode: mode,
        // تطبيق الاتجاه من اليمين لليسار على كامل التطبيق
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        // شاشة البداية (Splash) ثم التوجيه إلى الشاشة المناسبة
        home: const WelcomeScreen(),
        routes: {
          '/home': (context) => const _HomeGate(),
        },
      ),
    );
  }
}

/// بوابة الشاشة الرئيسية – تختار الوجهة حسب وجود توكن ودور المستخدم
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

/// تحديد الشاشة الأولى بناءً على وجود توكن صلاحية ودور المستخدم
Future<Widget> _initialScreen() async {
  final token = await ApiService.getToken();
  if (token == null) {
    // لا يوجد توكن → شاشة الترحيب (تسجيل الدخول أو الاشتراك)
    return const WelcomeScreen();
  }
  // يوجد توكن → توجيه حسب الدور (معلم، مختص، أو الشاشة العامة)
  return homeScreenForRole();
}
