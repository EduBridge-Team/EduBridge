import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/accessibility_service.dart';
import 'services/api_service.dart';
import 'screens/welcome_screen.dart';
import 'theme.dart';
import 'utils/home_router.dart';
import 'utils/navigation.dart';
import 'widgets/accessibility/adaptive_scaffold.dart';
import 'widgets/pet_assistant_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSavedThemeMode();
  await ApiService.initializeAuthState();
  await AccessibilityService.instance.load(); // ✅ جديد

  runApp(const ProviderScope(child: EduBridgeApp()));
}

class EduBridgeApp extends StatelessWidget {
  const EduBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: jisrThemeMode,
      builder: (context, mode, _) => ValueListenableBuilder<AccessibilityProfile>(
        valueListenable: AccessibilityService.instance.profile,
        builder: (context, accProfile, __) => MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'EduBridge — جسر تعليمي',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          // ✅ اختيار الثيم حسب البروفايل النشط
          theme: accProfile.highContrast
              ? buildHighContrastTheme()
              : buildJisrTheme(),
          darkTheme: buildJisrDarkTheme(),
          themeMode: mode,
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: PetAssistantOverlay(
              child: AdaptiveScaffold(child: child!), // ✅ جديد
            ),
          ),
          home: const WelcomeScreen(),
          routes: {
            '/home': (context) => const _HomeGate(),
          },
        ),
      ),
    );
  }
}

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

Future<Widget> _initialScreen() async {
  final token = await ApiService.getToken();
  if (token == null) {
    return const WelcomeScreen();
  }
  return homeScreenForRole();
}