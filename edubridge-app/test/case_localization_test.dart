import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/case_discussion/case_discussion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _response(Object data, [int status = 200]) => http.Response(jsonEncode(data), status,
  headers: {'content-type': 'application/json; charset=utf-8'});
Map<String, Object?> _case({String status = 'open'}) => {
  'id': 9, 'child_id': 7, 'child_name': 'محمود', 'topic': 'موضوع الدراسة الأصلي',
  'disability_type': 'متلازمة داون', 'created_at': '2026-10-01', 'status': status,
  'participants': [{'user_id': 2, 'name': 'مختص أصلي', 'role': 'specialist'}, {'user_id': 3, 'name': 'معلم أصلي', 'role': 'teacher'}],
  'messages': [{'id': 21, 'discussion_id': 9, 'sender_id': 3, 'sender_name': 'معلم أصلي',
    'sender_role': 'teacher', 'content': 'ملاحظة الفريق الأصلية', 'type': 'observation', 'created_at': '2026-10-01T14:30:00'}],
};
MockClient _client({bool empty = false, bool failList = false,
  Future<http.Response> Function(http.Request)? write}) => MockClient((request) async {
  if (request.method != 'GET') return write == null ? _response({}, 500) : await write(request);
  if (request.url.path.endsWith('/case-discussions/9')) return _response({'discussion': _case()});
  if (request.url.path.endsWith('/case-discussions')) {
    return _response({'discussions': empty ? [] : [_case()]}, failList ? 500 : 200);
  }
  if (request.url.path.endsWith('/children')) {
    return _response({'children': [
    {'id': 7, 'name': 'محمود', 'assigned_teacher_id': 3, 'specialist_ids': [2]},
    {'id': 8, 'name': 'طفل غير معيّن', 'assigned_teacher_id': 99, 'specialist_ids': [99]},
    ]});
  }
  if (request.url.path.endsWith('/users')) {
    return _response({'users': [
    {'id': 2, 'name': 'مختص أصلي', 'role': 'specialist'},
    {'id': 3, 'name': 'معلم أصلي', 'role': 'teacher'},
    {'id': 99, 'name': 'مستخدم خارج الفريق', 'role': 'teacher'},
    ]});
  }
  return _response({'user': {'id': 2, 'name': 'مختص أصلي'}, 'verification': {'verification_status': 'approved'}});
});
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!), home: screen));
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
Future<void> _tap(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
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
  setUp(() {
    SharedPreferences.setMockInitialValues({'role': 'specialist', 'userId': 2, 'name': 'مختص أصلي'});
    FlutterSecureStorage.setMockInitialValues({});
  });
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$language case list empty and populated scale=$scale', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await http.runWithClient(() async {
          await _mount(tester, const CaseDiscussionScreen(), language, scale: scale);
          expect(find.text(strings.caseStudies), findsWidgets);
          expect(find.text('موضوع الدراسة الأصلي'), findsOneWidget);
          expect(find.text(strings.caseActiveCount(1)), findsOneWidget);
        }, () => _client());
        await tester.pumpWidget(const SizedBox.shrink());
        await http.runWithClient(() async {
          await _mount(tester, const CaseDiscussionScreen(), language, scale: scale);
          expect(find.text(strings.caseListEmpty), findsOneWidget);
          expect(find.text(strings.caseNewAction), findsOneWidget);
        }, () => _client(empty: true));
      });
      testWidgets('$language case messages scale=$scale preserve draft on send failure', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        final writes = <http.Request>[];
        await http.runWithClient(() async {
          await _mount(tester, const CaseDiscussionScreen(discussionId: 9), language, scale: scale);
          expect(find.text(strings.caseTitleFor('محمود')), findsOneWidget);
          expect(find.text('ملاحظة الفريق الأصلية'), findsOneWidget);
          await tester.enterText(find.byType(TextField), 'رسالة أصلية');
          await _tap(tester, find.byTooltip(strings.send));
          expect(jsonDecode(writes.single.body), {'content': 'رسالة أصلية', 'type': 'text'});
          expect(writes.single.url.path, endsWith('/case-discussions/9/messages'));
          expect(find.text('رسالة أصلية'), findsOneWidget);
          expect(find.text(strings.messageSendFailed), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }, () => _client(write: (request) async {
          writes.add(request);
          return _response({}, 500);
        }));
      });
    }
    for (final role in ['specialist', 'teacher']) {
      testWidgets('$language $role case creation preserves child and team permissions', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        SharedPreferences.setMockInitialValues({'role': role, 'userId': role == 'teacher' ? 3 : 2});
        http.Request? saved;
        await http.runWithClient(() async {
          await _mount(tester, const CaseDiscussionScreen(), language);
          await _tap(tester, find.text(strings.caseNewAction));
          await _tap(tester, find.byKey(const ValueKey('s21_create')));
          expect(find.text(strings.caseChooseChild), findsOneWidget);
          await _tap(tester, find.byKey(const ValueKey('s21_child_selector')));
          expect(find.text('طفل غير معيّن'), findsNothing);
          await _tap(tester, find.text('محمود').last);
          await tester.enterText(find.byKey(const ValueKey('s21_topic')), 'موضوع أصلي');
          await tester.enterText(find.byKey(const ValueKey('s21_description')), 'وصف أصلي');
          await _tap(tester, find.byKey(const ValueKey('s21_create')));
          expect(find.text(strings.caseChooseParticipant), findsOneWidget);
          expect(find.text('مستخدم خارج الفريق'), findsNothing);
          await _tap(tester, find.byType(CheckboxListTile));
          await _tap(tester, find.byKey(const ValueKey('s21_create')));
          final data = jsonDecode(saved!.body) as Map;
          expect(data['child_id'], 7);
          expect(data['topic'], 'موضوع أصلي');
          expect(data['description'], 'وصف أصلي');
          expect(data['participant_ids'], unorderedEquals([2, 3]));
          expect(find.byType(NewCaseStudyDialogS21), findsNothing);
        }, () => _client(write: (request) async {
          saved = request;
          return _response({'discussion': _case()}, 201);
        }));
      });
    }
    testWidgets('$language case list failure stays retryable', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      var fail = true;
      await http.runWithClient(() async {
        await _mount(tester, const CaseDiscussionScreen(), language);
        expect(find.text(strings.caseListEmpty), findsNothing);
        expect(find.text(strings.caseListLoadFailed), findsOneWidget);
        fail = false;
        await _tap(tester, find.text(strings.retryAction));
        expect(find.text(strings.caseListEmpty), findsOneWidget);
      }, () => MockClient((request) async => _response({'discussions': []}, fail ? 500 : 200)));
    });
  }
}
