import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/specialist/specialist_child_profile_screen.dart';
import 'package:edubridge_app/screens/teacher/teacher_child_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget screen, String language, double scale) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!),
  home: screen,
);
http.Response _response(Object data, [int status = 200]) => http.Response(
  jsonEncode(data), status, headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'userId': 1, 'name': 'ليان'});
  });
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final specialist in [false, true]) {
        testWidgets('$language profile specialist=$specialist at $scale preserves authored data', (tester) async {
          await tester.binding.setSurfaceSize(const Size(360, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final child = <String, dynamic>{'id': 8, 'name': 'ليان', 'age': 9,
            'status': 'active', 'disability_description': 'وصف كتبه المختص'};
          await http.runWithClient(() async {
            final s = await AppLocalizations.delegate.load(Locale(language));
            await tester.runAsync(() async {
              await tester.pumpWidget(_host(specialist
                ? SpecialistChildProfileScreen(child: child)
                : TeacherChildProfileScreen(child: child), language, scale));
              await Future<void>.delayed(Duration.zero);
            });
            await tester.pumpAndSettle();
            expect(find.text(s.studentProfileFor('ليان')), findsOneWidget);
            expect(find.text('ليان'), findsWidgets);
            expect(find.text('وصف كتبه المختص'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          }, () => MockClient((request) async {
            if (request.url.path.endsWith('/accessibility-profile')) return _response({'can_edit': false});
            if (request.url.path.endsWith('/lessons')) return _response({'lessons': []});
            if (request.url.path.contains('/progress/child/')) return _response({'progress': []});
            return _response({'child': child});
          }));
        });
      }
    }
    testWidgets('$language assignment preview keeps follow-up and document tools hidden', (tester) async {
      final s = await AppLocalizations.delegate.load(Locale(language));
      final paths = <String>[];
      await http.runWithClient(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(_host(SpecialistChildProfileScreen(
            child: const {'id': 8, 'name': 'ليان'}, onAccept: (_) async {}), language, 1));
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pumpAndSettle();
        expect(find.text(s.previewInformationNotice), findsOneWidget);
        expect(find.text(s.documentsVerification), findsNothing);
        expect(find.text(s.evaluateChildPlan), findsNothing);
        expect(find.text(s.adaptLearning), findsNothing);
        expect(find.text(s.acceptChildFollowUp), findsOneWidget);
        expect(paths.where((p) => p.endsWith('/accessibility-profile')), isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/assignment-preview')) {
          return _response({'child': {'id': 8, 'name': 'ليان', 'assignment_preview': true}});
        }
        return _response({}, 403);
      }));
    });
  }
}
