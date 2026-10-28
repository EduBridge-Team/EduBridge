import 'dart:convert';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/specialist/specialist_screen.dart';
import 'package:edubridge_app/screens/specialist/support_target_dialog_s28.dart';
import 'package:edubridge_app/screens/teacher/teacher_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

http.Response _response(Object data, [int status = 200]) => http.Response(
  jsonEncode(data), status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

MockClient _client({bool hasLesson = false, bool verified = true}) => MockClient((request) async {
  if (request.url.path.endsWith('/teachers/me/sections')) {
    return _response({'contract_version': 1, 'sections': []});
  }
  if (request.url.path.endsWith('/me/verification')) {
    return _response({'verification': {'verification_status': verified ? 'approved' : 'none'}});
  }
  if (request.url.path.endsWith('/me')) {
    return _response({'user': {'id': 2, 'specialty': 'educational'}});
  }
  return _response({
    'children': [], 'users': [], 'disability_types': [], 'homeworks': [],
    'lessons': hasLesson ? [{
      'id': 51, 'title': 'دورة حياة الفراشة', 'content': 'محتوى كتبه المعلم',
      'target_type': 'everyone', 'created_at': '2026-10-19',
    }] : [],
  });
});

Future<void> _open(WidgetTester tester, Widget screen, String language, double scale) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.runAsync(() async {
    await tester.pumpWidget(_host(screen, language, scale: scale));
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'userId': 2, 'name': 'ليان', 'role': 'specialist'});
  });

  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final teacher in [true, false]) {
        for (final tab in teacher ? [0, 1, 2] : [0, 1]) {
          testWidgets('${teacher ? 'teacher' : 'specialist'} tab $tab in $language at $scale', (tester) async {
            await http.runWithClient(() async {
              await _open(tester, teacher ? TeacherScreen(initialTab: tab)
                  : SpecialistDashboardScreen(initialTab: tab), language, scale);
              final strings = await AppLocalizations.delegate.load(Locale(language));
              expect(find.text(teacher ? strings.academicSections : strings.children), findsWidgets);
              if (tab == 1) {
                await tester.scrollUntilVisible(find.text(strings.noLessonsYet), 120,
                  scrollable: find.descendant(of: find.byType(CustomScrollView),
                    matching: find.byType(Scrollable)).first);
                expect(find.text(strings.noLessonsYet), findsOneWidget);
              } else if (teacher && tab == 2) {
                expect(find.text(strings.noHomeworkInCategory), findsOneWidget);
              } else {
                expect(find.text(teacher ? (language == 'en' ? 'No sections currently assigned to you.' : 'لا توجد شُعب مكلّف بها حاليًا.') : strings.noAssignedChildren), findsOneWidget);
              }
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
            }, () => _client());
          });
        }
      }
    }
  }

  for (final teacher in [true, false]) {
    testWidgets('English ${teacher ? 'teacher' : 'specialist'} keeps authored lesson language', (tester) async {
      await http.runWithClient(() async {
        await _open(tester, teacher ? const TeacherScreen(initialTab: 1)
            : const SpecialistDashboardScreen(initialTab: 1), 'en', 1);
        expect(find.text('دورة حياة الفراشة'), findsOneWidget);
        expect(find.text('For everyone'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => _client(hasLesson: true));
    });
  }

  testWidgets('English support target validates and returns the unchanged enum', (tester) async {
    SupportRecommendationTarget? result;
    await tester.pumpWidget(_host(Scaffold(body: Builder(builder: (context) => TextButton(
      onPressed: () async {
        result = await showDialog<SupportRecommendationTarget>(context: context,
          builder: (_) => const SupportTargetDialogS28(childName: 'محمود'));
      }, child: const Text('Open'),
    ))), 'en'));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Learning support recommendation — محمود'), findsOneWidget);
    expect(tester.getCenter(find.text('Cancel')).dx, lessThan(tester.getCenter(find.text('Next')).dx));
    await tester.tap(find.byKey(const ValueKey('s28-next')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a recipient for the support recommendation'), findsOneWidget);
    expect(result, isNull);
    await tester.tap(find.byKey(const ValueKey('s28-parent')));
    await tester.tap(find.byKey(const ValueKey('s28-next')));
    await tester.pumpAndSettle();
    expect(result, SupportRecommendationTarget.parent);
    expect(tester.takeException(), isNull);
  });
}
