import 'dart:async';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/welcome_screen.dart';
import 'package:edubridge_app/services/app_locale_controller.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host({Brightness brightness = Brightness.light}) => ValueListenableBuilder<Locale>(
  valueListenable: AppLocaleController.instance,
  builder: (context, locale, _) => MaterialApp(
    locale: locale,
    theme: brightness == Brightness.dark ? buildJisrDarkTheme() : buildJisrTheme(),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
    home: const WelcomeScreen(),
  ),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocaleController.instance.load();
  });

  testWidgets('direct language button switches the current tour page without resetting it', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('أسرة ومعلم ومختص\nفي مكان واحد'), findsOneWidget);
    expect(find.text('الخطوة 2 من 3'), findsNothing);
    final languageButton = tester.widget<IconButton>(find.byKey(const ValueKey('onboarding-language')));
    expect((languageButton.icon as Icon).icon, Icons.language);
    await tester.tap(find.byKey(const ValueKey('onboarding-language')));
    await tester.pumpAndSettle();
    expect(find.text('اختر اللغة'), findsOneWidget);
    await tester.runAsync(() async {
      final changed = Completer<void>();
      void listener() {
        if (AppLocaleController.instance.value.languageCode == 'en' && !changed.isCompleted) changed.complete();
      }
      AppLocaleController.instance.addListener(listener);
      try {
        await tester.tap(find.byKey(const ValueKey('language_en')));
        await changed.future.timeout(const Duration(seconds: 5));
      } finally {
        AppLocaleController.instance.removeListener(listener);
      }
    });
    await tester.pumpAndSettle();
    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(strings.tourTeamTitle), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.byTooltip('Language'), findsOneWidget);
    expect(find.text('Language'), findsNothing);
    expect(Directionality.of(tester.element(find.byKey(const ValueKey('onboarding-language')))), TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('landing globe button sits beside the theme control in $brightness', (tester) async {
      await tester.pumpWidget(_host(brightness: brightness));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تخطي'));
      await tester.pumpAndSettle();
      final language = find.byKey(const ValueKey('welcome-language'));
      final button = tester.widget<IconButton>(language);
      expect((button.icon as Icon).icon, Icons.language);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      final themeIcon = brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
      final themeButton = find.widgetWithIcon(IconButton, themeIcon);
      expect(tester.getSize(language), tester.getSize(themeButton));
      expect(tester.getCenter(language).dy, tester.getCenter(themeButton).dy);
      expect((tester.getCenter(language).dx - tester.getCenter(themeButton).dx).abs(),
        (tester.getSize(language).width + tester.getSize(themeButton).width) / 2 + 8);
      await tester.tap(language);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('language_en')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
