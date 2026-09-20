// main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/accessibility_service.dart';
import 'services/api_service.dart';
import 'services/notification_listener_service.dart';
import 'services/overlay_visibility_service.dart';
import 'services/user_settings_sync_service.dart';
import 'services/websocket_service.dart';
import 'screens/notifications_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme.dart';
import 'utils/home_router.dart';
import 'utils/navigation.dart';
import 'widgets/accessibility/adaptive_scaffold.dart';
import 'widgets/accessibility/voice_mic_overlay.dart';
import 'widgets/notification_snackbar.dart';
import 'widgets/pet_assistant_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _EduBridgeBootstrap());
}

/// Shows the branded animated splash immediately while all local startup state
/// is prepared, then swaps atomically to the real application.
class _EduBridgeBootstrap extends StatefulWidget {
  const _EduBridgeBootstrap();

  @override
  State<_EduBridgeBootstrap> createState() => _EduBridgeBootstrapState();
}

class _EduBridgeBootstrapState extends State<_EduBridgeBootstrap> {
  Widget? _initialHome;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    // Give the reveal enough time to read naturally while startup work happens
    // in parallel. The app never waits longer than necessary for slow startup.
    final minimumSplash =
        Future<void>.delayed(const Duration(milliseconds: 3600));

    await Future.wait([
      loadSavedThemeMode(),
      ApiService.initializeAuthState(),
      AccessibilityService.instance.load(),
      OverlayVisibilityService.initialize(),
    ]);

    final token = await ApiService.getToken();
    final Widget destination;
    if (token == null) {
      destination = const WelcomeScreen();
    } else {
      destination = await homeScreenForRole();
    }

    await minimumSplash;
    if (!mounted) return;

    _restoreApplicationSystemBars();
    setState(() => _initialHome = destination);

    // Network-backed services remain non-blocking after the first app frame.
    if (token != null) {
      unawaited(_startAuthenticatedServices(token));
    }
  }

  void _restoreApplicationSystemBars() {
    final dark = jisrThemeMode.value == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            dark ? const Color(0xFF0B1E30) : AppColors.cream,
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destination = _initialHome;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: destination == null
          ? const MaterialApp(
              key: ValueKey('edubridge-splash'),
              debugShowCheckedModeBanner: false,
              home: EduBridgeSplashScreen(),
            )
          : EduBridgeApp(
              key: const ValueKey('edubridge-app'),
              initialHome: destination,
            ),
    );
  }
}

Future<void> _startAuthenticatedServices(String token) async {
  await UserSettingsSyncService.syncFromServer();
  WebSocketService().connect(token);
  await NotificationListenerService.instance.initialize();
}

class EduBridgeApp extends StatelessWidget {
  final Widget initialHome;

  const EduBridgeApp({
    super.key,
    this.initialHome = const WelcomeScreen(),
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: jisrThemeMode,
      builder: (context, mode, _) =>
          ValueListenableBuilder<AccessibilityProfile>(
        valueListenable: AccessibilityService.instance.applicationProfile,
        builder: (context, accProfile, __) => MaterialApp(
          navigatorKey: appNavigatorKey,
          navigatorObservers: [jisrModalRouteObserver],
          title: 'EduBridge — جسر تعليمي',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          theme: accProfile.highContrast
              ? buildHighContrastTheme()
              : buildJisrTheme(),
          darkTheme: buildJisrDarkTheme(),
          themeMode: mode,
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: NotificationSnackbarHost(
              child: PetAssistantOverlay(
                child: VoiceMicOverlay(
                  child: SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    bottom: false,
                    child: AdaptiveScaffold(child: child!),
                  ),
                ),
              ),
            ),
          ),
          home: initialHome,
          routes: {
            '/home': (context) => const _HomeGate(),
            '/notifications': (context) => const NotificationsScreen(),
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
  await UserSettingsSyncService.syncFromServer();
  return homeScreenForRole();
}
