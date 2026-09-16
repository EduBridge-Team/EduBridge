// main.dart
import 'package:flutter/material.dart';
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
  runApp(const EduBridgeBootstrap());
}

class EduBridgeBootstrap extends StatefulWidget {
  const EduBridgeBootstrap({super.key});

  @override
  State<EduBridgeBootstrap> createState() => _EduBridgeBootstrapState();
}

class _EduBridgeBootstrapState extends State<EduBridgeBootstrap> {
  late final Future<Widget> _initialHomeFuture = _initializeApp();

  Future<Widget> _initializeApp() async {
    await loadSavedThemeMode();
    await ApiService.initializeAuthState();
    await AccessibilityService.instance.load();
    await OverlayVisibilityService.initialize();

    final token = await ApiService.getToken();
    if (token == null) {
      return const WelcomeScreen();
    }

    // Remote preferences override local defaults when available.
    // If the backend is offline, the service keeps the locally saved values.
    await UserSettingsSyncService.syncFromServer();

    WebSocketService().connect(token);
    await NotificationListenerService.instance.initialize();
    return homeScreenForRole();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialHomeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'EduBridge',
            home: SplashScreen(),
          );
        }

        return EduBridgeApp(
          initialHome: snapshot.data ?? const WelcomeScreen(),
        );
      },
    );
  }
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
        valueListenable: AccessibilityService.instance.profile,
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
