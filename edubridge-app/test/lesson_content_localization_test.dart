import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/utils/content_speech_language.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_text.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_video_player.dart';
import 'package:edubridge_app/widgets/accessibility/step_by_step_lesson.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> host(WidgetTester tester, String language, Widget child) async {
  await tester.pumpWidget(MaterialApp(locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, body) => MediaQuery(data: MediaQuery.of(context).copyWith(
      textScaler: const TextScaler.linear(2)), child: body!), home: child));
  await tester.pumpAndSettle();
}
Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target); await tester.tap(target);
  await tester.pumpAndSettle(); await tester.pump(const Duration(milliseconds: 400));
}
void main() {
  test('content voice inference has explicit override and neutral-content fallback', () {
    expect(ContentSpeechLanguage.resolve('هذا محتوى المعلم الأصلي'), 'ar');
    expect(ContentSpeechLanguage.resolve('The teacher wrote this lesson'), 'en');
    expect(ContentSpeechLanguage.resolve('A lesson for ليان about the sun'), 'en');
    expect(ContentSpeechLanguage.resolve('123', fallback: 'en'), 'en');
    expect(ContentSpeechLanguage.resolve('English', override: 'ar'), 'ar');
  });
  testWidgets('lesson controls localize while content, step position and spoken content language are preserved', (tester) async {
    final service = AccessibilityService.instance;
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      sensoryCalmMode: true, slowSpeech: true, realLifeLinking: true);
    addTearDown(service.resetSession);
    final calls = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async { calls.add(call); return 1; });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetDevicePixelRatio); addTearDown(tester.view.resetPhysicalSize);
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    for (final content in ['محتوى أصلي من المعلم', 'Original content from the teacher']) {
      final lesson = StepByStepLesson(lessonTitle: 'عنوان أصلي', childName: 'ليان', steps: [
        LessonStep(title: 'عنوان مولد', generatedNumber: 1, content: content, realLifeExample: content),
        LessonStep(title: 'عنوان مولد', generatedNumber: 2, content: content),
      ]);
      await host(tester, 'en', lesson);
      expect(find.text('عنوان أصلي'), findsOneWidget);
      expect(find.text(en.stepLessonPosition(1, 2)), findsOneWidget);
      expect(find.text(en.childLessonsStep('1')), findsOneWidget);
      expect(find.text(content), findsNWidgets(2));
      expect(calls.where((c) => c.method == 'speak'), isEmpty);
      await tap(tester, find.text(en.stepLessonListen));
      expect(calls.where((c) => c.method == 'setLanguage').last.arguments, ContentSpeechLanguage.resolve(content));
      expect(calls.where((c) => c.method == 'setSpeechRate').last.arguments, 0.30);
      final args = calls.where((c) => c.method == 'speak').last.arguments;
      expect(args is Map ? args['text'] : args, contains(content));
      await tap(tester, find.text(en.stepLessonNext));
      await host(tester, 'ar', lesson);
      expect(find.text(ar.stepLessonPosition(2, 2)), findsOneWidget);
      expect(find.text(ar.childLessonsStep('2')), findsOneWidget);
      expect(find.text(content), findsOneWidget);
      await tap(tester, find.text(ar.stepLessonPrevious));
      expect(find.text(ar.stepLessonPosition(1, 2)), findsOneWidget);
      await tap(tester, find.text(ar.stepLessonNext));
      await tap(tester, find.text(ar.stepLessonFinish));
      expect(find.text(ar.stepLessonEffort), findsOneWidget);
      await host(tester, 'en', lesson);
      expect(find.text(en.stepLessonComplete('عنوان أصلي')), findsOneWidget);
      await tap(tester, find.text(en.stepLessonReview));
      expect(find.text(en.stepLessonPosition(1, 2)), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink()); calls.clear();
    }
    await host(tester, 'en', const StepByStepLesson(lessonTitle: 'Original', steps: [], childName: 'ليان'));
    expect(find.text(en.stepLessonEmpty), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    service.profile.value = service.profile.value.copyWith(sensoryCalmMode: false, autoReadOnTap: true);
    await host(tester, 'en', const Scaffold(body: AdaptiveText('نص أصلي', speechLanguageCode: 'ar')));
    await tap(tester, find.byType(AdaptiveText));
    expect(calls.where((c) => c.method == 'setLanguage').last.arguments, 'ar');
    await host(tester, 'en', const Scaffold(body: AdaptiveText('Read this instruction')));
    await tap(tester, find.byType(AdaptiveText));
    expect(calls.where((c) => c.method == 'setLanguage').last.arguments, 'en');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('video initialization failure and fallback title follow locale', (tester) async {
    const video = AdaptiveVideoPlayer(videoUrl: 'http://[');
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    await host(tester, 'en', video);
    expect(find.text(en.lessonVideoTitle), findsOneWidget);
    expect(find.text(en.lessonVideoFailed), findsOneWidget);
    await host(tester, 'ar', video);
    expect(find.text(ar.lessonVideoFailed), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
