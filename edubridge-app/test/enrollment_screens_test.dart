import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/enrollment/school_dashboard_screen.dart';
import 'package:edubridge_app/screens/enrollment/parent_enrollment_screen.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/utils/home_router.dart';

import 'enrollment_fakes.dart';

Widget host(Widget child, String language, {double scale = 1}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: child,
);
Future<void> searchSchool(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('enrollment-school-query')),
    'School',
  );
  await tester.tap(find.byKey(const ValueKey('enrollment-school-search')));
  await tester.pumpAndSettle();
  await tester.ensureVisible(
    find.byKey(const ValueKey('enrollment-submit-10')),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'role': 'school',
      'name': 'Operator',
    });
    FlutterSecureStorage.setMockInitialValues({});
  });
  test('school role routes to its own dashboard', () async {
    expect(await homeScreenForRole(), isA<SchoolDashboardScreen>());
  });
  for (final language in ['ar', 'en']) {
    testWidgets('school inbox fits narrow viewport with large $language text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          SchoolDashboardScreen(gateway: FakeSchoolEnrollment()),
          language,
          scale: 2,
        ),
      );
      await tester.runAsync(() async {
        await SharedPreferences.getInstance();
      });
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('enrollment-reject-50'));
      await tester.scrollUntilVisible(
        action,
        150,
        scrollable: find
            .descendant(
              of: find.byWidgetPredicate((widget) => widget is ScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(action, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'parent history fits narrow viewport with large $language text',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final gateway = FakeParentEnrollment()
          ..requests = [enrollmentRequest()];
        await tester.pumpWidget(
          host(
            ParentEnrollmentScreen(
              childId: 6,
              childName: 'Child A',
              gateway: gateway,
            ),
            language,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        final action = find.byKey(const ValueKey('enrollment-cancel-50'));
        await tester.scrollUntilVisible(
          action,
          150,
          scrollable: find
              .descendant(
                of: find.byWidgetPredicate((widget) => widget is ScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(action, findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('school approval requires section before sending decision', (
    tester,
  ) async {
    final gateway = FakeSchoolEnrollment();
    await tester.pumpWidget(
      host(SchoolDashboardScreen(gateway: gateway), 'en'),
    );
    await tester.runAsync(() async {
      await SharedPreferences.getInstance();
    });
    await tester.pumpAndSettle();
    final approve = find.byKey(const ValueKey('enrollment-approve-50'));
    await tester.ensureVisible(approve);
    await tester.tap(approve);
    await tester.pumpAndSettle();
    final confirm = find.byKey(const ValueKey('enrollment-decision-confirm'));
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(gateway.writes, 0);
    expect(find.text('Choose a section for enrollment.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('enrollment-section')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026/2027 / Grade 2 / A').last);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(gateway.writes, 1);
    expect(gateway.lastDecision!.sectionId, 20);
    expect(find.text('Approved'), findsOneWidget);
  });
  testWidgets('school rejection requires reason and preserves it', (
    tester,
  ) async {
    final gateway = FakeSchoolEnrollment();
    await tester.pumpWidget(
      host(SchoolDashboardScreen(gateway: gateway), 'en'),
    );
    await tester.runAsync(() async {
      await SharedPreferences.getInstance();
    });
    await tester.pumpAndSettle();
    final reject = find.byKey(const ValueKey('enrollment-reject-50'));
    await tester.ensureVisible(reject);
    await tester.tap(reject);
    await tester.pumpAndSettle();
    final confirm = find.byKey(const ValueKey('enrollment-decision-confirm'));
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(gateway.writes, 0);
    await tester.enterText(
      find.byKey(const ValueKey('enrollment-reason')),
      'Full capacity',
    );
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(gateway.writes, 1);
    expect(gateway.lastDecision!.approve, isFalse);
  });
  testWidgets('cancelling parent submission confirmation sends nothing', (
    tester,
  ) async {
    final gateway = FakeParentEnrollment();
    await tester.pumpWidget(
      host(
        ParentEnrollmentScreen(
          childId: 6,
          childName: 'Child A',
          gateway: gateway,
        ),
        'en',
      ),
    );
    await tester.pumpAndSettle();
    await searchSchool(tester);
    await tester.tap(find.byKey(const ValueKey('enrollment-submit-10')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(gateway.writes, 0);
  });
  testWidgets('parent submission shows canonical pending history', (
    tester,
  ) async {
    final gateway = FakeParentEnrollment();
    await tester.pumpWidget(
      host(
        ParentEnrollmentScreen(
          childId: 6,
          childName: 'Child A',
          gateway: gateway,
        ),
        'en',
      ),
    );
    await tester.pumpAndSettle();
    await searchSchool(tester);
    await tester.tap(find.byKey(const ValueKey('enrollment-submit-10')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(gateway.writes, 1);
    expect(find.text('Pending'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('enrollment-submit-10')),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets(
    'unavailable school service has no fabricated counters or request actions',
    (tester) async {
      final gateway = FakeSchoolEnrollment()
        ..loadFailure = EnrollmentFailure.unavailable;
      await tester.pumpWidget(
        host(SchoolDashboardScreen(gateway: gateway), 'en'),
      );
      await tester.runAsync(() async {
        await SharedPreferences.getInstance();
      });
      await tester.pumpAndSettle();
      expect(
        find.text('Enrollment is not available on the server yet.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('enrollment-approve-50')), findsNothing);
    },
  );
}
