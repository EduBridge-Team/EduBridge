import 'dart:convert';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/enrollment/parent_enrollment_screen.dart';
import 'package:edubridge_app/screens/parent_screen.dart';
import 'package:edubridge_app/screens/institution_statistics_screen.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'userId': 1, 'role': 'parent', 'name': 'Parent'});
  });
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('parent actions adapt at $width in $language', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final scale = width == 320 ? 2.0 : 1.0;
        final l10n = await AppLocalizations.delegate.load(Locale(language));
        await http.runWithClient(() async {
          await tester.runAsync(() async {
            await tester.pumpWidget(MaterialApp(
              locale: Locale(language), supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
              home: const ParentScreen(),
            ));
            await Future<void>.delayed(Duration.zero);
          });
          await tester.pumpAndSettle();
          final enrollment = find.widgetWithText(OutlinedButton, l10n.enrollmentParentTitle);
          final support = find.widgetWithText(OutlinedButton, l10n.requestLearningSupport);
          await tester.scrollUntilVisible(enrollment, 200,
            scrollable: find.descendant(of: find.byType(ListView),
              matching: find.byType(Scrollable)).first);
          await Scrollable.ensureVisible(tester.element(enrollment), alignment: 0.5);
          await tester.pumpAndSettle();
          expect(enrollment, findsOneWidget);
          expect(support, findsOneWidget);
          final e = tester.getRect(enrollment);
          final s = tester.getRect(support);
          if (width >= 720) {
            expect((e.top - s.top).abs(), lessThan(1));
            expect(e.overlaps(s), isFalse);
          } else {
            expect(e.top, greaterThan(s.top));
          }
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            await tester.tap(enrollment);
            await tester.pump();
            await Future<void>.delayed(Duration.zero);
          });
          await tester.pumpAndSettle();
          expect(find.byType(ParentEnrollmentScreen), findsOneWidget);
          expect(find.byType(BrandAppBar), findsOneWidget);
          expect(find.byType(BackButton), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }, () => MockClient((request) async {
          if (request.url.path.endsWith('/children')) {
            return http.Response(jsonEncode({'children': [{
              'id': 6, 'name': 'Long child name اسم طفل طويل لاختبار الشاشة',
              'age': 7, 'status': 'assigned',
              'disability_type': 'Long description وصف طويل لاختبار التفاف النص',
            }]}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
          }
          if (request.url.path.endsWith('/enrollment-requests')) {
            return http.Response(jsonEncode({
              'child_id': 6, 'requests': [], 'active_enrollment': null,
            }), 200);
          }
          return http.Response('{}', 200);
        }));
      });
    }
  }
  for (final width in [320.0, 1280.0]) {
    testWidgets('institution statistics adapt at $width with large text', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await http.runWithClient(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
              child: child!),
            home: const InstitutionStatisticsScreen(),
          ));
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Attendance sessions'), 200,
          scrollable: find.descendant(of: find.byType(ListView),
            matching: find.byType(Scrollable)).first);
        expect(find.text('Attendance sessions'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient((request) async => http.Response(jsonEncode(
        request.url.path.endsWith('/my-organization')
          ? {'organization': {'id': 4, 'slug': 'demo-institution'}}
          : {'summary': {'schools': 0, 'student_files': 5,
              'active_teachers': 2, 'active_enrollments': 0, 'attendance_sessions': 0},
             'schools': []}), 200)));
    });
  }

}
