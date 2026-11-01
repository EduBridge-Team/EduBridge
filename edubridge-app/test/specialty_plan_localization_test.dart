import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/choose_specialty_screen.dart';
import 'package:edubridge_app/screens/specialist_picker_sheet.dart';
import 'package:edubridge_app/screens/educational_plan_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _response(Object data, [int status = 200]) => http.Response(jsonEncode(data), status,
  headers: {'content-type': 'application/json; charset=utf-8'});
Map<String, Object?> _evaluation() => {
  'id': 1, 'child_id': 7, 'created_at': '2026-01-01T00:00:00Z', 'recommendations': 'توصية أصلية', 'educational_plan': 'خطة كتبها المختص',
  'cognitive_assessment': 'وصف معرفي أصلي', 'motor_assessment': 'وصف حركي أصلي',
  'emotional_assessment': 'وصف عاطفي أصلي', 'social_assessment': 'وصف اجتماعي أصلي',
  'teaching_methods': ['تعلم باللعب', 'طريقة تدريس طويلة كتبها المختص لتناسب احتياجات الطفل الفردية'],
};
MockClient _client({bool empty = false, List<http.Request>? writes,
  Future<http.Response> Function(http.Request)? write}) => MockClient((request) async {
  if (request.method != 'GET') {
    writes?.add(request);
    return write == null ? _response({}, 204) : await write(request);
  }
  expect(request.url.path.endsWith('/evaluations/child/7'), isTrue);
  return _response({'evaluations': empty ? [] : [_evaluation()]});
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
  });
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final specialty in ['learning_support', 'educational']) {
        testWidgets('$language specialty $specialty at $scale preserves API value', (tester) async {
          final strings = await AppLocalizations.delegate.load(Locale(language));
          final writes = <http.Request>[];
          var done = false;
          await http.runWithClient(() async {
            await _mount(tester, ChooseSpecialtyScreen(onDone: () => done = true), language, scale: scale);
            final confirm = find.widgetWithText(ElevatedButton, strings.specialtyConfirm);
            await tester.scrollUntilVisible(confirm, 180, scrollable: find.byType(Scrollable).first);
            expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
            tester.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
            await tester.pumpAndSettle();
            await _tap(tester, find.text(specialty == 'learning_support'
              ? strings.learningSupportSpecialist : strings.educationalSpecialist));
            await _tap(tester, find.text(strings.specialtyConfirm));
            expect(done, isTrue);
            expect(writes.single.url.path.endsWith('/me/specialty'), isTrue);
            expect(jsonDecode(writes.single.body), {'specialty': specialty});
          }, () => _client(writes: writes));
        });
      }
      testWidgets('$language educational plan at $scale preserves authored assessment and teaching methods', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await http.runWithClient(() async {
          await _mount(tester, const Scaffold(body: EducationalPlanSheet(child: {'id': 7, 'name': 'محمود'})), language, scale: scale);
          expect(find.text(strings.planChildTitle('محمود')), findsOneWidget);
          expect(find.text(strings.planRecommendationsValue('توصية أصلية')), findsOneWidget);
          expect(find.text(strings.planContentValue('خطة كتبها المختص')), findsOneWidget);
          expect(find.text('وصف معرفي أصلي'), findsOneWidget);
          expect(find.text('تعلم باللعب'), findsOneWidget);
          expect(find.text('طريقة تدريس طويلة كتبها المختص لتناسب احتياجات الطفل الفردية'), findsOneWidget);
        }, () => _client());
      });
      testWidgets('$language specialist picker at $scale preserves names emails and selected map', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        final specialist = {'id': 3, 'name': 'اسم المختص الأصلي الطويل للتجربة', 'email': 'specialist@example.org'};
        Map? selected;
        await _mount(tester, Scaffold(body: SpecialistPickerSheet(childName: 'محمود',
          specialists: [specialist, {'id': 4, 'name': '', 'email': ''}], onSelect: (value) => selected = value)), language, scale: scale);
        expect(find.text(strings.specialistPickerIntro('محمود')), findsOneWidget);
        expect(find.text('specialist@example.org'), findsOneWidget);
        await _tap(tester, find.text(specialist['name'] as String));
        expect(identical(selected, specialist), isTrue);
        expect(find.text(strings.specialistRole), findsOneWidget);
      });
    }
    testWidgets('$language specialty failure retains selection and retries', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      final writes = <http.Request>[];
      var done = false;
      await http.runWithClient(() async {
        await _mount(tester, ChooseSpecialtyScreen(onDone: () => done = true), language, scale: 2);
        await _tap(tester, find.text(strings.learningSupportSpecialist));
        await _tap(tester, find.text(strings.specialtyConfirm));
        expect(find.text(strings.specialtySaveFailed), findsOneWidget);
        expect(done, isFalse);
        await _tap(tester, find.text(strings.specialtyConfirm));
        expect(writes, hasLength(2));
        expect(jsonDecode(writes.last.body), {'specialty': 'learning_support'});
        expect(done, isTrue);
      }, () => _client(writes: writes, write: (_) async =>
        writes.length == 1 ? _response({'error': 'رسالة سيرفر'}, 500) : _response({}, 204)));
    });
    testWidgets('$language empty educational plan and specialist picker', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      await http.runWithClient(() async {
        await _mount(tester, const Scaffold(body: EducationalPlanSheet(child: {'id': 7, 'name': 'محمود'})), language, scale: 2);
        expect(find.text(strings.planEvaluationMissing), findsOneWidget);
      }, () => _client(empty: true));
      await _mount(tester, Scaffold(body: SpecialistPickerSheet(childName: 'محمود', specialists: const [], onSelect: (_) {})), language, scale: 2);
      expect(find.text(strings.specialistPickerEmpty), findsOneWidget);
    });
  }
}
