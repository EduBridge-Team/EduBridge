import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/add_lesson/add_lesson_sheet.dart';
import 'package:edubridge_app/screens/lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _response(Object data, [int status = 200]) => http.Response(
  jsonEncode(data), status, headers: {'content-type': 'application/json; charset=utf-8'});
MockClient _client({bool empty = false, bool fail = false, List<http.Request>? writes}) => MockClient((request) async {
  if (request.method == 'GET' && request.url.path.endsWith('/ratings')) {
    return _response({'average': 4.5, 'count': 2, 'ratings': [{'user_name': 'معلم أصلي', 'stars': 4, 'comment': 'تعليق أصلي'}]});
  }
  if (request.method == 'POST') {
    writes?.add(request);
    return _response({'lesson': {'id': 12}}, fail ? 500 : 201);
  }
  if (request.url.path.endsWith('/children')) {
    return _response({'children': [{'id': 7, 'name': 'محمود', 'disability_type': 'متلازمة داون'}]});
  }
  return _response({'lessons': empty ? [] : [{'id': 12, 'title': 'درس المعلم الأصلي', 'content': 'نص المحتوى الأصلي'}],
    'pagination': {'page': 1, 'last_page': 1, 'total': empty ? 0 : 1}}, fail ? 500 : 200);
});
Future<void> _mount(WidgetTester tester, Widget screen, String language, double scale) async {
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
    SharedPreferences.setMockInitialValues({'role': 'teacher', 'userId': 3});
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (_) async => 1);
  });
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$language authoring audiences and localized validation at $scale', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await http.runWithClient(() async {
          await _mount(tester, Scaffold(body: AddLessonSheet(types: const [{'id': 5, 'name': 'متلازمة داون'}],
            fullScreen: true, onClose: () {}, onCreated: (_) {})), language, scale);
          expect(find.text(strings.lessonTitleField), findsOneWidget);
          await tester.tap(find.text(strings.lessonSave));
          await tester.pumpAndSettle();
          await _tap(tester, find.text(strings.lessonSpecificStudents));
          expect(find.text('محمود'), findsOneWidget);
          await _tap(tester, find.text('محمود'));
          await _tap(tester, find.text(strings.lessonAllStudents));
          await _tap(tester, find.text(strings.lessonForParents));
          expect(find.text(strings.lessonAudience), findsNothing);
          expect(find.text(strings.lessonParentsOnlyHint), findsOneWidget);
        }, () => _client());
      });
      testWidgets('$language locked child save preserves authored text and API target at $scale', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        final writes = <http.Request>[];
        Map? created;
        await http.runWithClient(() async {
          await _mount(tester, Scaffold(body: AddLessonSheet(types: const [], fullScreen: true,
            initialChildId: 7, initialChildName: 'محمود', onClose: () {}, onCreated: (value) => created = value)), language, scale);
          expect(find.text(strings.lessonOnlyStudent('محمود')), findsOneWidget);
          expect(find.byType(SwitchListTile), findsNothing);
          await tester.enterText(find.byType(TextField).at(0), 'عنوان أصلي');
          await tester.enterText(find.byType(TextField).at(1), 'محتوى من المعلم');
          await _tap(tester, find.text(strings.lessonSave));
          expect(created?['id'], 12);
          final body = utf8.decode(writes.single.bodyBytes);
          expect(body, contains('عنوان أصلي'));
          expect(body, contains('محتوى من المعلم'));
          expect(body, contains('specificChildren'));
          expect(body, contains('[7]'));
        }, () => _client(writes: writes));
      });
      testWidgets('$language browsing preserves authored lessons at $scale', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await http.runWithClient(() async {
          await _mount(tester, const LessonsScreen(), language, scale);
          expect(find.text(strings.lessonBrowse), findsOneWidget);
          expect(find.text('درس المعلم الأصلي'), findsOneWidget);
          expect(find.text('نص المحتوى الأصلي'), findsOneWidget);
        }, () => _client());
      });
    }
    testWidgets('$language parent audience does not retain a student-only target', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      final writes = <http.Request>[];
      await http.runWithClient(() async {
        await _mount(tester, Scaffold(body: AddLessonSheet(types: const [], fullScreen: true,
          onClose: () {}, onCreated: (_) {})), language, 1);
        await tester.enterText(find.byType(TextField).first, 'درس للأسرة');
        await _tap(tester, find.text(strings.lessonSpecificStudents));
        await _tap(tester, find.text(strings.lessonForParents));
        await _tap(tester, find.text(strings.lessonSave));
        final body = utf8.decode(writes.single.bodyBytes);
        expect(body, contains('parents'));
        expect(body, contains('درس للأسرة'));
        expect(body, isNot(contains('target_child_ids')));
        expect(find.byType(CircularProgressIndicator), findsNothing);
      }, () => _client(writes: writes));
    });
    testWidgets('$language rating sheet preserves comments and numeric stars at large text', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      final writes = <http.Request>[];
      await http.runWithClient(() async {
        await _mount(tester, const LessonsScreen(), language, 2);
        await _tap(tester, find.text(strings.evaluate));
        expect(find.text(strings.lessonRatingSummary('4.5', 2)), findsOneWidget);
        expect(find.text('تعليق أصلي'), findsOneWidget);
        await _tap(tester, find.byTooltip(strings.lessonRatingStars(4)));
        await tester.enterText(find.byType(TextField).last, 'تقييم من المستخدم');
        await _tap(tester, find.text(strings.saveEvaluation));
        final data = jsonDecode(writes.single.body) as Map<String, dynamic>;
        expect(data['stars'], 4);
        expect(data['comment'], 'تقييم من المستخدم');
      }, () => _client(writes: writes));
    });
    testWidgets('$language browsing empty and error states', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      await http.runWithClient(() async {
        await _mount(tester, const LessonsScreen(), language, 1);
        expect(find.text(strings.noLessonsYet), findsOneWidget);
      }, () => _client(empty: true));
      await tester.pumpWidget(const SizedBox.shrink());
      await http.runWithClient(() async {
        await _mount(tester, const LessonsScreen(), language, 1);
        expect(find.text(strings.lessonsLoadFailed), findsOneWidget);
      }, () => _client(fail: true));
    });
  }
}
