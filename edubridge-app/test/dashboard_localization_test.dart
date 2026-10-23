import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/institution_screen.dart';
import 'package:edubridge_app/screens/profile/profile_screen.dart';
import 'package:edubridge_app/widgets/dashboard_profile_identity.dart';
import 'package:edubridge_app/widgets/legal_links_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, String language, {double scale = 1}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: child,
);

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'name': 'ليان'});
  });

  test('dashboard child counts use complete Arabic and English messages', () async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(ar.dashboardChildCount(0), 'لا يوجد أطفال');
    expect(ar.dashboardChildCount(1), 'طفل واحد');
    expect(ar.dashboardChildCount(2), 'طفلان');
    expect(ar.dashboardChildCount(3), '3 أطفال');
    expect(ar.dashboardChildCount(11), '11 طفلًا');
    expect(ar.dashboardChildCount(100), '100 طفل');
    expect(en.dashboardChildCount(0), 'No children');
    expect(en.dashboardChildCount(1), '1 child');
    expect(en.dashboardChildCount(2), '2 children');
    expect(en.dashboardGreeting('ليان'), 'Hello, ليان');
  });

  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('institution dashboard fits 360px in $language at $scale', (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_host(const InstitutionScreen(), language, scale: scale));
        // Complete preference reads without waiting on an avatar's loading frames.
        await tester.runAsync(() async {
          await SharedPreferences.getInstance();
        });
        await tester.pump();
        final tasksHeading =
            find.text(language == 'en' ? 'Institution tasks' : 'مهام المؤسسة');
        // New school actions can place this heading below the first viewport,
        // especially at 200% text scale. Verify it after scrolling into view.
        await tester.scrollUntilVisible(
          tasksHeading,
          150,
          scrollable: find.byType(Scrollable).last,
        );
        expect(tasksHeading, findsOneWidget);
        final identity = tester.element(find.byType(DashboardProfileIdentity));
        expect(Directionality.of(identity), language == 'en' ? TextDirection.ltr : TextDirection.rtl);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  for (final language in ['ar', 'en']) {
    testWidgets('legal menu scrolls on a small screen with large $language text', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_host(const Scaffold(body: LegalLinksButton()), language, scale: 2));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      final warning = find.text(language == 'en'
          ? 'Your account and all its data will be deleted. This cannot be undone.'
          : 'سيتم حذف حسابك وكل بياناتك — لا يمكن التراجع');
      await tester.ensureVisible(warning);
      await tester.pumpAndSettle();
      expect(warning, findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('legal entry reuses localized confirmation and cancel never deletes', (tester) async {
    await tester.pumpWidget(_host(const Scaffold(body: LegalLinksButton()), 'en'));
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Privacy and account'), findsOneWidget);
    await tester.tap(find.text('Permanently delete account'));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteAccountDialog), findsOneWidget);
    final deleteButton = find.widgetWithText(ElevatedButton, 'Delete permanently');
    expect(tester.widget<ElevatedButton>(deleteButton).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'حذف');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(deleteButton).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(deleteButton).onPressed, isNotNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteAccountDialog), findsNothing);
    expect(find.byType(LegalLinksButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
