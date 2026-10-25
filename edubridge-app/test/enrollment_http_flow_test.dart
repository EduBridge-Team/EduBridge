import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/enrollment/parent_enrollment_screen.dart';
import 'package:edubridge_app/screens/enrollment/school_dashboard_screen.dart';
import 'package:edubridge_app/services/enrollment/enrollment_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'enrollment_fakes.dart';
import 'enrollment_http_fixtures.dart';

Widget host(Widget screen, String language) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  ),
  home: screen,
);

Future<void> reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find
                    .byWidgetPredicate((widget) => widget is ScrollView)
                    .first,
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find
          .descendant(
            of: find.byWidgetPredicate((widget) => widget is ScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await reveal(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> resume(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
}

Future<void> pullToRefresh(WidgetTester tester) async {
  final scrollable = find
      .descendant(
        of: find.byWidgetPredicate((widget) => widget is ScrollView).first,
        matching: find.byType(Scrollable),
      )
      .first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pump();
  await tester.drag(
    find.byWidgetPredicate((widget) => widget is ScrollView).first,
    const Offset(0, 350),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'name': 'School A',
      'role': 'school',
    });
  });
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets(
        'parent HTTP flow, resume and refresh in $language at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final fixture = ParentEnrollmentHttpFixture();
          final strings = await AppLocalizations.delegate.load(
            Locale(language),
          );
          await tester.pumpWidget(
            host(
              ParentEnrollmentScreen(
                childId: 6,
                childName: 'Child A',
                gateway: ParentEnrollmentRepository(
                  childId: 6,
                  client: fixture.client,
                ),
              ),
              language,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(BackButton), findsOneWidget);
          await tester.enterText(
            find.byKey(const ValueKey('enrollment-school-query')),
            'School',
          );
          await tapVisible(
            tester,
            find.byKey(const ValueKey('enrollment-school-search')),
          );
          await tapVisible(
            tester,
            find.byKey(const ValueKey('enrollment-submit-10')),
          );
          await tapVisible(tester, find.text(strings.enrollmentConfirm));
          await reveal(tester, find.text(strings.enrollmentPending));
          expect(find.text(strings.enrollmentPending), findsOneWidget);
          expect(fixture.writes, ['/parent/children/6/enrollment-requests']);
          await reveal(
            tester,
            find.byKey(const ValueKey('enrollment-submit-10')),
          );
          expect(
            tester
                .widget<FilledButton>(
                  find.byKey(const ValueKey('enrollment-submit-10')),
                )
                .onPressed,
            isNull,
          );
          await tapVisible(
            tester,
            find.byKey(const ValueKey('enrollment-cancel-50')),
          );
          await tapVisible(tester, find.text(strings.enrollmentConfirm));
          await reveal(tester, find.text(strings.enrollmentCancelled));
          expect(find.text(strings.enrollmentCancelled), findsOneWidget);
          expect(fixture.writes.length, 2);
          // A later decision by the school/another guardian is visible on resume.
          fixture.requests = [
            ...fixture.requests,
            {
              ...enrollmentRequestJson(status: 'approved', version: 2),
              'id': 51,
            },
          ];
          fixture.active = activeEnrollmentJson();
          tester
              .state<ScrollableState>(
                find
                    .descendant(
                      of: find
                          .byWidgetPredicate((widget) => widget is ScrollView)
                          .first,
                      matching: find.byType(Scrollable),
                    )
                    .first,
              )
              .position
              .jumpTo(0);
          final reads = fixture.reads;
          await resume(tester);
          expect(fixture.reads, reads + 1);
          expect(
            find.text('${strings.enrollmentActive}: School A'),
            findsOneWidget,
          );
          await reveal(
            tester,
            find.byKey(const ValueKey('enrollment-submit-10')),
          );
          expect(
            tester
                .widget<FilledButton>(
                  find.byKey(const ValueKey('enrollment-submit-10')),
                )
                .onPressed,
            isNull,
          );
          await pullToRefresh(tester);
          expect(fixture.reads, reads + 2);
          expect(fixture.writes.length, 2);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );

      testWidgets(
        'school HTTP decision and resumed inbox in $language at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final fixture = SchoolEnrollmentHttpFixture();
          final strings = await AppLocalizations.delegate.load(
            Locale(language),
          );
          await tester.pumpWidget(
            host(
              SchoolDashboardScreen(
                gateway: SchoolEnrollmentRepository(client: fixture.client),
              ),
              language,
            ),
          );
          await tester.runAsync(() async => SharedPreferences.getInstance());
          await tester.pumpAndSettle();
          await tapVisible(
            tester,
            find.byKey(const ValueKey('enrollment-reject-50')),
          );
          await tester.enterText(
            find.byKey(const ValueKey('enrollment-reason')),
            'No capacity',
          );
          await tapVisible(
            tester,
            find.byKey(const ValueKey('enrollment-decision-confirm')),
          );
          expect(fixture.decisions.single, {
            'expected_version': 1,
            'decision': 'rejected',
            'section_id': null,
            'reason': 'No capacity',
          });
          expect(find.text(strings.enrollmentNoRequests), findsOneWidget);
          fixture.requests = [
            {...enrollmentRequestJson(), 'id': 51},
          ];
          final reads = fixture.inboxReads;
          await resume(tester);
          expect(fixture.inboxReads, reads + 1);
          expect(
            find.byKey(const ValueKey('enrollment-approve-51')),
            findsOneWidget,
          );
          await pullToRefresh(tester);
          expect(fixture.inboxReads, reads + 2);
          expect(fixture.decisions.length, 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
