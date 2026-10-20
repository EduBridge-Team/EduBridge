import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/child_homework/child_homework_screen.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _response(Object data, [int code = 200]) => http.Response(jsonEncode(data), code,
  headers: {'content-type': 'application/json; charset=utf-8'});
Map<String, Object?> _homework({bool submitted = false, bool late = false, bool overdue = false}) => {
  'id': 8, 'title': 'واجب المعلم الأصلي', 'description': 'وصف المعلم الأصلي',
  'teacher_name': 'اسم المعلم الأصلي', 'subject': 'مادة أصلية',
  'due_date': overdue ? '2000-01-01' : '2099-12-15', 'created_at': '2026-10-01',
  'assigned_child_ids': [7], 'submissions': submitted ? [{
    'id': 42, 'homework_id': 8, 'child_id': 7,
    'submitted_at': '2026-10-12T14:30:00', 'text_answer': 'إجابة الطفل الأصلية',
    'grade': 88, 'feedback': 'ملاحظة المعلم الأصلية', 'is_late': late,
  }] : [],
};
MockClient _client({List<Object?>? homework, Future<http.Response> Function(http.Request)? write}) => MockClient((request) async {
  if (request.method != 'GET') {
    return write == null ? _response({}, 500) : await write(request);
  }
  if (request.url.path.endsWith('/homeworks')) {
    expect(request.url.queryParameters['child_id'], '7');
    return _response({'homeworks': homework ?? [_homework()]});
  }
  if (request.url.path.endsWith('/accessibility-profile')) {
    return _response({'profile': const AccessibilityProfile(type: DisabilityType.none,
      extraLargeTouchTargets: true).toJson()});
  }
  throw StateError('Unexpected request: ${request.url}');
});
const _screen = ChildHomeworkScreen(childId: 7, childName: 'محمود');
Future<void> _mount(WidgetTester tester, Widget screen, String language, {double scale = 1}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.runAsync(() async {
    await tester.pumpWidget(MaterialApp(locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale)), child: child!), home: screen));
    for (var frame = 0; frame < 3; frame++) {
      await Future<void>.delayed(Duration.zero);
      await tester.pump();
    }
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
Future<void> _tap(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 180, scrollable: find.byType(Scrollable).first);
  }
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(target.hitTestable());
    await tester.pump();
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'userId': 1});
    FlutterSecureStorage.setMockInitialValues({});
    AccessibilityService.instance.resetSession();
    await AccessibilityService.instance.load();
  });
  tearDown(AccessibilityService.instance.resetSession);
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final state in ['pending', 'overdue', 'submitted', 'late']) {
        testWidgets('$language $state homework at $scale preserves authored content', (tester) async {
          final strings = await AppLocalizations.delegate.load(Locale(language));
          await http.runWithClient(() async {
            await _mount(tester, _screen, language, scale: scale);
            expect(find.text(strings.childHomeworkFor('محمود')), findsOneWidget);
            expect(find.text('واجب المعلم الأصلي'), findsOneWidget);
            expect(find.text('وصف المعلم الأصلي'), findsOneWidget);
            final status = switch (state) {
              'overdue' => strings.childHomeworkOverdue,
              'submitted' => strings.childHomeworkSubmitted,
              'late' => strings.childHomeworkSubmittedLate,
              _ => strings.homeworkPendingFilter,
            };
            expect(find.text(status), findsOneWidget);
            if (state == 'submitted' || state == 'late') {
              final feedback = find.text(strings.childHomeworkFeedback('ملاحظة المعلم الأصلية'));
              await tester.scrollUntilVisible(feedback, 160, scrollable: find.byType(Scrollable).first);
              expect(feedback, findsOneWidget);
              expect(find.text(strings.childHomeworkYourAnswer('إجابة الطفل الأصلية')), findsOneWidget);
              expect(find.text(strings.childHomeworkGrade('88')), findsOneWidget);
              expect(find.text(strings.childHomeworkSubmit), findsNothing);
            }
          }, () => _client(homework: [_homework(submitted: state == 'submitted' || state == 'late',
            late: state == 'late', overdue: state == 'overdue')]));
        });
      }
      testWidgets('$language submission validation at $scale retains the original answer on retry', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        final writes = <http.Request>[];
        await http.runWithClient(() async {
          await _mount(tester, _screen, language, scale: scale);
          await _tap(tester, find.text(strings.childHomeworkSubmit));
          expect(find.text(strings.childHomeworkSheetTitle('واجب المعلم الأصلي')), findsOneWidget);
          await _tap(tester, find.text(strings.childHomeworkSend));
          expect(find.text(strings.childHomeworkAnswerRequired), findsOneWidget);
          expect(writes, isEmpty);
          await tester.enterText(find.byType(TextField), 'إجابتي الأصلية Original answer');
          await _tap(tester, find.text(strings.childHomeworkSend));
          expect(find.text(strings.childHomeworkSubmitError), findsOneWidget);
          expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'إجابتي الأصلية Original answer');
          await _tap(tester, find.text(strings.childHomeworkSend));
          expect(find.byType(TextField), findsNothing);
          expect(writes, hasLength(2));
          for (final request in writes) {
            expect(request.url.path.endsWith('/homeworks/8/submit'), isTrue);
            final body = utf8.decode(request.bodyBytes);
            expect(body, contains('name="child_id"'));
            expect(body, contains('name="text_answer"'));
            expect(body, contains('إجابتي الأصلية Original answer'));
            expect(body, isNot(contains('locale')));
          }
        }, () => _client(write: (request) async {
          writes.add(request);
          return writes.length == 1 ? _response({'error': 'خطأ الخادم'}, 500)
            : _response({'submission': {'id': 42}}, 201);
        }));
      });
    }
    testWidgets('$language empty homework state', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      await http.runWithClient(() async {
        await _mount(tester, _screen, language);
        expect(find.text(strings.childHomeworkEmpty), findsOneWidget);
        expect(find.text(strings.childHomeworkEmptyHint), findsOneWidget);
      }, () => _client(homework: []));
    });
  }
}
