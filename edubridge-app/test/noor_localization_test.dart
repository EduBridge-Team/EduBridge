import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/assistant_screen.dart';
import 'package:edubridge_app/screens/student_noor_screen.dart';
import 'package:edubridge_app/services/assistant_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _response(Object data, [int status = 200]) => http.Response(jsonEncode(data), status,
  headers: {'content-type': 'application/json; charset=utf-8'});
MockClient _client({List<http.Request>? writes, bool empty = false}) => MockClient((request) async {
  if (request.method == 'POST') {
    writes?.add(request);
    return _response({'reply': 'رد نور الأصلي بالعربية'});
  }
  return _response({'prompt_context': 'محتوى الطالب الأصلي', 'recommended_actions': empty ? [] : [
    {'priority': 'high', 'title': 'اقتراح أصلي من الخادم', 'reason': 'سبب أصلي', 'prompt': 'نص المناقشة الأصلي'},
  ]});
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
    SharedPreferences.setMockInitialValues({'role': 'specialist', 'userId': 2});
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (_) async => 1);
  });
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final role in ['parent', 'teacher', 'specialist']) {
        testWidgets('$language $role Noor greeting and suggestions at $scale', (tester) async {
          SharedPreferences.setMockInitialValues({'role': role, 'userId': 2});
          final strings = await AppLocalizations.delegate.load(Locale(language));
          await _mount(tester, const AssistantScreen(), language, scale: scale);
          expect(find.text(strings.noorTitle), findsOneWidget);
          expect(find.text(strings.noorWelcome), findsOneWidget);
          final suggestion = switch (role) {
            'parent' => strings.noorParentToday,
            'teacher' => strings.noorSimplerTeaching,
            _ => strings.noorExplainLesson,
          };
          expect(find.text(suggestion), findsOneWidget);
          expect(find.byTooltip(strings.noorClearConversation), findsOneWidget);
        });
      }
      testWidgets('$language student Noor at $scale preserves server content and teacher-only draft action', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await http.runWithClient(() async {
          await _mount(tester, const StudentNoorScreen(childId: 7, childName: 'محمود'), language, scale: scale);
          expect(find.text(strings.noorStudentTitle('محمود')), findsOneWidget);
          expect(find.text('اقتراح أصلي من الخادم'), findsOneWidget);
          expect(find.text('سبب أصلي'), findsOneWidget);
          expect(find.text(strings.noorCreateHomework), findsNothing);
          expect(find.text(strings.noorAskStudent), findsOneWidget);
        }, () => _client());
      });
    }
    testWidgets('$language send/regenerate preserves messages lesson context and unchanged API contract', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      final writes = <http.Request>[];
      await http.runWithClient(() async {
        await _mount(tester, const AssistantScreen(lessonContext: 'درس أصلي من المعلم'), language);
        await tester.enterText(find.byType(TextField), 'سؤال كتبه المستخدم');
        await _tap(tester, find.byTooltip(strings.send));
        expect(find.text('رد نور الأصلي بالعربية'), findsOneWidget);
        final body = jsonDecode(writes.first.body) as Map<String, dynamic>;
        expect(body.keys.toSet(), {'messages', 'context'});
        expect((body['messages'] as List).single, {'role': 'user', 'content': 'سؤال كتبه المستخدم'});
        expect(body['context'], contains('درس أصلي من المعلم'));
        // App localization does not override the server's Arabic response policy.
        final direction = tester.widget<Directionality>(find.ancestor(
          of: find.text('رد نور الأصلي بالعربية'), matching: find.byType(Directionality)).first);
        expect(direction.textDirection, TextDirection.rtl);
        await _tap(tester, find.byTooltip(strings.noorRegenerateTooltip));
        expect(writes, hasLength(2));
        expect(jsonDecode(writes.last.body)['messages'], body['messages']);
        final history = await AssistantService.loadHistory();
        expect(history.first.content, 'سؤال كتبه المستخدم');
        expect(history.last.content, 'رد نور الأصلي بالعربية');
      }, () => _client(writes: writes));
    });
    testWidgets('$language existing conversation survives display and clearing restores localized greeting', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      await AssistantService.saveHistory(const [AssistantMessage(role: 'user', content: 'رسالة قديمة'),
        AssistantMessage(role: 'assistant', content: 'Existing English reply')]);
      await _mount(tester, const AssistantScreen(), language);
      expect(find.text('Existing English reply'), findsOneWidget);
      expect(find.text('رسالة قديمة'), findsOneWidget);
      await _tap(tester, find.byTooltip(strings.noorClearConversation));
      expect(find.text(strings.noorWelcome), findsOneWidget);
      expect(await AssistantService.loadHistory(), isEmpty);
    });
    testWidgets('$language student Noor empty state keeps teacher draft action', (tester) async {
      SharedPreferences.setMockInitialValues({'role': 'teacher', 'userId': 3});
      final strings = await AppLocalizations.delegate.load(Locale(language));
      await http.runWithClient(() async {
        await _mount(tester, const StudentNoorScreen(childId: 7, childName: 'محمود'), language, scale: 2);
        expect(find.text(strings.noorNoFollowup), findsOneWidget);
        expect(find.text(strings.noorCreateHomework), findsOneWidget);
      }, () => _client(empty: true));
    });
  }
}
