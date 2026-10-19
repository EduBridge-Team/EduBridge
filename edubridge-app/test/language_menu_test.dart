import 'dart:async';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/main.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/app_locale_controller.dart';
import 'package:edubridge_app/widgets/dashboard_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final locale = AppLocaleController.instance;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await locale.load();
    AccessibilityService.instance.resetSession();
  });
  tearDown(() => AccessibilityService.instance.resetSession());

  testWidgets('changing language preserves the open route, input and child settings', (tester) async {
    const profile = AccessibilityProfile(type: DisabilityType.none, largeMouseCursor: true);
    AccessibilityService.instance.activeChildId.value = 9;
    AccessibilityService.instance.profile.value = profile;
    Future<void> choose(String language) async {
      // Preference I/O uses real async time; pumpAndSettle only advances frames.
      // Wait for the persisted preference notification before settling the UI.
      await tester.runAsync(() async {
        final changed = Completer<void>();
        void onChanged() {
          if (locale.value.languageCode == language && !changed.isCompleted) {
            changed.complete();
          }
        }
        locale.addListener(onChanged);
        try {
          await tester.tap(find.byKey(ValueKey('language_$language')));
          await changed.future.timeout(const Duration(seconds: 5));
        } finally {
          locale.removeListener(onChanged);
        }
      });
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const EduBridgeApp(initialHome: _MenuTestHome()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
    final state = Navigator.of(tester.element(find.byType(TextField)));
    await tester.enterText(find.byType(TextField), 'درس أضافه المعلم');
    await tester.tap(find.byTooltip('المزيد من الخيارات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اللغة'));
    await tester.pumpAndSettle();
    await choose('en');
    final fieldContext = tester.element(find.byType(TextField));
    expect(locale.value, const Locale('en'));
    expect(Localizations.localeOf(fieldContext), const Locale('en'));
    expect(Directionality.of(fieldContext), TextDirection.ltr);
    expect(Navigator.of(fieldContext), same(state));
    expect(state.canPop(), isTrue);
    expect(find.text('درس أضافه المعلم'), findsOneWidget);
    expect(AccessibilityService.instance.profile.value, same(profile));
    expect(AccessibilityService.instance.activeChildId.value, 9);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await choose('ar');
    expect(Directionality.of(tester.element(find.byType(TextField))), TextDirection.rtl);
    expect(find.text('درس أضافه المعلم'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  for (final specialistStyle in [false, true]) {
    testWidgets('language entry works in shared menu style=$specialistStyle without invoking role actions', (tester) async {
      var actionCalls = 0;
      await tester.pumpWidget(ValueListenableBuilder<Locale>(valueListenable: locale,
        builder: (context, value, _) => MaterialApp(
          locale: value,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(appBar: AppBar(actions: [DashboardMenu(
            specialistFigmaMenu: specialistStyle,
            actions: [DashboardMenuAction(id: 'support', label: 'الدعم الفني',
              icon: Icons.help_outline, onSelected: () => actionCalls++)],
          )])),
        ),
      ));
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('اللغة'), findsOneWidget);
      await tester.tap(find.text('اللغة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(locale.value, const Locale('ar'));
      expect(actionCalls, 0);
      expect(tester.takeException(), isNull);
    });
  }
}

class _MenuTestHome extends StatelessWidget {
  const _MenuTestHome();
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: TextButton(
    onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
      builder: (_) => Scaffold(appBar: AppBar(actions: const [DashboardMenu(actions: [])]),
        body: const TextField()),
    )),
    child: const Text('افتح'),
  )));
}
