import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/child_lessons/child_lessons_screen.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _response(Object data, [int code = 200]) => http.Response(jsonEncode(data), code,
  headers: {'content-type': 'application/json; charset=utf-8'});
const _lesson = <String, Object?>{
  'id': 8, 'title': 'عنوان الدرس الأصلي', 'content': 'نص المعلم الأصلي English content',
  'video_url': 'https://example.test/video.mp4', 'audio_url': 'https://example.test/audio.mp3',
  'audio_description': 'وصف صوتي أصلي', 'images': ['first.png', 'second.png'],
  'image_descriptions': ['وصف الصورة الأصلي'],
};
MockClient _client({bool empty = false, bool done = false,
  Future<http.Response> Function(http.Request)? write, bool Function()? failLoad}) => MockClient((request) async {
  if (request.method != 'GET') {
    return write == null ? _response({}, 500) : await write(request);
  }
  if (request.url.path.endsWith('/lessons')) {
    expect(request.url.path.endsWith('/children/7/lessons'), isTrue);
    return failLoad?.call() == true ? _response({'error': 'رسالة الخادم'}, 500)
      : _response({'lessons': empty ? [] : [_lesson]});
  }
  if (request.url.path.endsWith('/progress/child/7')) {
    return _response({'progress': done ? [{'lesson_id': 8, 'status': 'done'}] : []});
  }
  if (request.url.path.endsWith('/accessibility-profile')) {
    return _response({'profile': const AccessibilityProfile(type: DisabilityType.none,
      extraLargeTouchTargets: true, textOnlyMode: true, stepByStepLessons: true).toJson()});
  }
  if (request.url.path.endsWith('/engagement')) return _response({'stars': 5});
  if (request.url.path.endsWith('/care-team')) return _response({'members': []});
  throw StateError('Unexpected request: ${request.url}');
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
  setUp(() async {
    SharedPreferences.setMockInitialValues({'userId': 1, 'role': 'parent'});
    FlutterSecureStorage.setMockInitialValues({});
    AccessibilityService.instance.resetSession();
    await AccessibilityService.instance.load();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (_) async => 1);
  });
  tearDown(AccessibilityService.instance.resetSession);
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final specialist in [false, true]) {
        testWidgets('$language lessons specialist=$specialist scale=$scale preserve teacher content', (tester) async {
          final strings = await AppLocalizations.delegate.load(Locale(language));
          await http.runWithClient(() async {
            await _mount(tester, ChildLessonsScreen(childId: 7, childName: 'محمود', specialistS10: specialist), language, scale: scale);
            expect(find.text(strings.childLessonsFor('محمود')), findsOneWidget);
            if (!specialist) {
              expect(find.text(strings.childLessonsGames), findsOneWidget);
              expect(find.text(strings.childLessonsPlayLearn), findsOneWidget);
              expect(find.text(strings.childLessonsDone), findsNothing);
            }
            await _tap(tester, find.text('عنوان الدرس الأصلي'));
            expect(find.text('نص المعلم الأصلي English content'), findsWidgets);
            expect(find.text('وصف الصورة الأصلي'), findsOneWidget);
            expect(find.text(strings.childLessonsImageFallback('2', 'عنوان الدرس الأصلي')), findsOneWidget);
            expect(find.text(strings.childLessonsReadEasy), findsOneWidget);
            expect(find.text(strings.childLessonsAudioDescription('وصف صوتي أصلي')), findsOneWidget);
            expect(find.text(strings.childLessonsPlayVideo), findsOneWidget);
            expect(find.text(strings.childLessonsPlayAudio), findsOneWidget);
            expect(find.text(strings.lessonRatingTitle), findsOneWidget);
            expect(find.text(strings.lessonAskNoor), findsOneWidget);
          }, () => _client(done: specialist));
        });
      }
      testWidgets('$language lesson card action states scale=$scale retain identifiers', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        int? marked; Map? opened; Map? spoken;
        await _mount(tester, Scaffold(body: Builder(builder: (context) => SingleChildScrollView(
          child: buildLessonCard(context: context, lesson: _lesson,
            doneLessonIds: {}, speakingLessonId: null, savingLessonId: null, canMarkDone: true,
            onOpenLesson: (lesson) => opened = lesson,
            onToggleSpeak: (lesson) async { spoken = lesson; },
            onMarkDone: (id) async { marked = id; }),
        ))), language, scale: scale);
        await _tap(tester, find.text(strings.childLessonsDone));
        expect(marked, 8);
        await _tap(tester, find.text(strings.listen));
        expect(spoken, same(_lesson));
        await _tap(tester, find.text('عنوان الدرس الأصلي'));
        expect(opened, same(_lesson));
      });
      testWidgets('$language specialist recommendation scale=$scale can retry without changing API values', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        final writes = <http.Request>[];
        await http.runWithClient(() async {
          await _mount(tester, const ChildLessonsScreen(childId: 7, childName: 'محمود', specialistS10: true), language, scale: scale);
          await _tap(tester, find.text(strings.childLessonsRecommendation));
          expect(find.text(strings.childLessonsChooseAction), findsOneWidget);
          await _tap(tester, find.text(strings.childLessonsRecommendParent));
          expect(find.text(strings.childLessonsRecommendFailed), findsOneWidget);
          await _tap(tester, find.text(strings.childLessonsRecommendParent));
          expect(find.text(strings.recommendationSentToParent), findsOneWidget);
          expect(writes, hasLength(2));
          for (final request in writes) {
            expect(request.url.path.endsWith('/lessons/8/recommend'), isTrue);
            expect(jsonDecode(request.body), {'child_id': 7});
          }
        }, () => _client(write: (request) async {
          writes.add(request);
          return writes.length == 1 ? _response({'error': 'رسالة الخادم'}, 500)
            : _response({'message': 'رسالة الخادم'}, 201);
        }));
      });
      testWidgets('$language routine instructions scale=$scale follow the interface language', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        AccessibilityService.instance.profile.value = const AccessibilityProfile(
          type: DisabilityType.none, predictableTimeline: true, extraLargeTouchTargets: true);
        await _mount(tester, Scaffold(body: Builder(builder: (context) => SingleChildScrollView(
          child: buildAdaptiveHeader(context: context, childId: 7, childName: 'محمود',
            parentPhone: null, specialistPhone: null, canMarkDone: false, timerCycle: 0,
            onOpenGames: () {}, onTimerFinished: () {}),
        ))), language, scale: scale);
        expect(find.text(strings.childLessonsTimeline), findsOneWidget);
        expect(find.text(strings.childLessonsChoose), findsOneWidget);
        expect(find.text(strings.childLessonsListenHelp), findsOneWidget);
        expect(find.text(strings.childLessonsTry), findsOneWidget);
        expect(find.text(strings.childLessonsReview), findsOneWidget);
      });
    }
    for (final specialist in [false, true]) {
      testWidgets('$language empty lessons specialist=$specialist', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await http.runWithClient(() async {
          await _mount(tester, ChildLessonsScreen(childId: 7, childName: 'محمود', specialistS10: specialist), language);
          final empty = find.text(strings.childLessonsEmpty);
          if (empty.evaluate().isEmpty) {
            await tester.scrollUntilVisible(empty, 160, scrollable: find.byType(Scrollable).first);
          }
          expect(empty, findsOneWidget);
        }, () => _client(empty: true));
      });
      testWidgets('$language failed lessons specialist=$specialist can retry', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        var failed = true;
        await http.runWithClient(() async {
          await _mount(tester, ChildLessonsScreen(childId: 7, childName: 'محمود', specialistS10: specialist), language);
          expect(find.text(strings.childLessonsLoadFailed), findsOneWidget);
          expect(find.text('رسالة الخادم'), findsNothing);
          failed = false;
          await _tap(tester, find.text(strings.retryAction));
          final lesson = find.text('عنوان الدرس الأصلي');
          if (lesson.evaluate().isEmpty) {
            await tester.scrollUntilVisible(lesson, 160, scrollable: find.byType(Scrollable).first);
          }
          expect(lesson, findsOneWidget);
        }, () => _client(failLoad: () => failed));
      });
    }
  }
}
