import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/model/learning_support_request_model.dart';
import 'package:edubridge_app/screens/create_learning_support_request_screen.dart';
import 'package:edubridge_app/screens/learning_support_meetings_screen.dart';
import 'package:edubridge_app/screens/learning_support_requests/learning_support_requests_screen.dart';
import 'package:edubridge_app/utils/learning_support_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _response(Object data, [int status = 200]) => http.Response(jsonEncode(data), status,
  headers: {'content-type': 'application/json; charset=utf-8'});
Map<String, Object?> _request({String status = 'pending'}) => {
  'id': 9, 'child_id': 7, 'child_name': 'محمود', 'parent_id': 4, 'parent_name': 'ولي الأمر الأصلي',
  'reason': 'صعوبة في فهم الدروس', 'description': 'وصف أصلي من الأسرة', 'urgency': 'high',
  'status': status, 'created_at': '2026-10-01',
  if (status == 'scheduled') 'scheduled_at': '2026-10-25T16:30:00',
};
Map<String, Object?> _session(int id, String status) => {
  'id': id, 'child_id': 7, 'child_name': 'محمود', 'specialist_id': 2,
  'specialist_name': 'المختص الأصلي', 'type': 'learningPlanning', 'status': status,
  'scheduled_at': '2026-10-25T16:30:00', 'duration_minutes': 45, 'notes': 'ملاحظة أصلية',
  'goals': 'الهدف الأصلي', 'recommendations': 'التوصية الأصلية', 'mood_rating': 4, 'tags': ['وسم أصلي'],
};
MockClient _client({bool empty = false, List<http.Request>? writes, bool failWrite = false}) => MockClient((request) async {
  if (request.method != 'GET') {
    writes?.add(request);
    return _response({'request': _request()}, failWrite ? 500 : request.method == 'POST' ? 201 : 200);
  }
  if (request.url.path.endsWith('/meetings')) {
    expect(request.url.queryParameters['child_id'], '7');
    return _response({'sessions': empty ? [] : [_session(1, 'scheduled'), _session(2, 'completed')]});
  }
  return _response({'requests': empty ? [] : [_request(), _request(status: 'scheduled')]});
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
  setUp(() {
    SharedPreferences.setMockInitialValues({'role': 'parent', 'userId': 4});
    FlutterSecureStorage.setMockInitialValues({});
  });
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final role in ['parent', 'specialist']) {
        testWidgets('$language $role request list at $scale preserves names and localizes reason/status', (tester) async {
          SharedPreferences.setMockInitialValues({'role': role, 'userId': role == 'parent' ? 4 : 2});
          final strings = await AppLocalizations.delegate.load(Locale(language));
          await http.runWithClient(() async {
            await _mount(tester, const LearningSupportRequestsScreen(), language, scale: scale);
            expect(find.text(strings.supportRequestsTitle), findsOneWidget);
            expect(find.text('محمود'), findsWidgets);
            expect(find.text(strings.supportReasonLabel(LearningSupportPresentation.reason('صعوبة في فهم الدروس', strings))), findsWidgets);
          }, () => _client());
        });
      }
      testWidgets('$language meetings filters and authored details at $scale', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await http.runWithClient(() async {
          await _mount(tester, const LearningSupportMeetingsScreen(childId: 7, childName: 'محمود'), language, scale: scale);
          expect(find.text(strings.supportChildMeetings('محمود')), findsOneWidget);
          expect(find.text('الهدف الأصلي'), findsWidgets);
          await _tap(tester, find.text(strings.supportScheduled).first);
          expect(find.text('الهدف الأصلي'), findsOneWidget);
          expect(find.textContaining('45', findRichText: true), findsWidgets);
        }, () => _client());
      });
    }
    testWidgets('$language parent and specialist empty request states', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      for (final role in ['parent', 'specialist']) {
        SharedPreferences.setMockInitialValues({'role': role});
        await http.runWithClient(() async {
          await _mount(tester, const LearningSupportRequestsScreen(), language);
          expect(find.text(strings.supportRequestsEmpty), findsOneWidget);
        }, () => _client(empty: true));
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
    testWidgets('$language create request sends canonical reason and priority with authored description', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      final writes = <http.Request>[];
      await http.runWithClient(() async {
        await _mount(tester, const CreateLearningSupportRequestScreen(childId: 7, childName: 'محمود'), language, scale: 2);
        await _tap(tester, find.text(strings.supportReasonHint));
        await _tap(tester, find.text(LearningSupportPresentation.reason('صعوبة في فهم الدروس', strings)).last);
        await tester.scrollUntilVisible(find.byType(TextFormField), 160, scrollable: find.byType(Scrollable).first);
        await tester.enterText(find.byType(TextFormField), 'شرح أصلي من ولي الأمر عن صعوبة التعلم');
        await _tap(tester, find.text(strings.supportPriorityHigh));
        await _tap(tester, find.text(strings.supportSendRequest));
        final data = jsonDecode(writes.single.body) as Map<String, dynamic>;
        expect(data, {'child_id': 7, 'reason': 'صعوبة في فهم الدروس',
          'description': 'شرح أصلي من ولي الأمر عن صعوبة التعلم', 'urgency': 'high'});
      }, () => _client(writes: writes));
    });
    testWidgets('$language failed create retains draft and allows retry', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      await http.runWithClient(() async {
        await _mount(tester, const CreateLearningSupportRequestScreen(childId: 7, childName: 'محمود'), language, scale: 2);
        await _tap(tester, find.text(strings.supportReasonHint));
        await _tap(tester, find.text(LearningSupportPresentation.reason('صعوبة في فهم الدروس', strings)).last);
        await tester.scrollUntilVisible(find.byType(TextFormField), 160, scrollable: find.byType(Scrollable).first);
        await tester.enterText(find.byType(TextFormField), 'وصف أصلي طويل بما يكفي لحفظ الطلب');
        await _tap(tester, find.text(strings.supportSendRequest));
        expect(find.text(strings.supportCreateFailed), findsOneWidget);
        expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, strings.supportSendRequest)).onPressed, isNotNull);
        expect(find.text('وصف أصلي طويل بما يكفي لحفظ الطلب'), findsOneWidget);
      }, () => _client(failWrite: true));
    });
    testWidgets('$language schedule validates and preserves URL notes and date payload', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      final material = await GlobalMaterialLocalizations.delegate.load(Locale(language));
      final writes = <http.Request>[];
      await http.runWithClient(() async {
        await _mount(tester, Scaffold(body: ScheduleLearningSupportSheet(
          request: LearningSupportRequest.fromJson(_request()))), language, scale: 2);
        await _tap(tester, find.text(strings.supportConfirm));
        expect(find.text(strings.supportDateTimeRequired), findsOneWidget);
        await _tap(tester, find.text(strings.supportChooseDate));
        await _tap(tester, find.text(material.okButtonLabel));
        await _tap(tester, find.text(strings.supportChooseTime));
        await _tap(tester, find.text(material.okButtonLabel));
        await _tap(tester, find.text(strings.supportConfirm));
        expect(find.text(strings.supportLinkRequired), findsOneWidget);
        await tester.enterText(find.byType(TextField).at(0), 'https://meet.google.com/abc-defg-hij');
        await tester.enterText(find.byType(TextField).at(1), 'ملاحظة أصلية من المختص');
        await _tap(tester, find.text(strings.supportConfirm));
        final data = jsonDecode(writes.single.body) as Map<String, dynamic>;
        expect(writes.single.url.path.endsWith('/requests/9/schedule'), isTrue);
        expect(data['meeting_link'], 'https://meet.google.com/abc-defg-hij');
        expect(data['specialist_notes'], 'ملاحظة أصلية من المختص');
        expect(DateTime.parse(data['scheduled_at'] as String).hour, 16);
      }, () => _client(writes: writes));
    });
  }
}
