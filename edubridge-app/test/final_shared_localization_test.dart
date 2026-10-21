import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/models/interactive_lesson.dart';
import 'package:edubridge_app/screens/interactive_lesson/interactive_lesson_player.dart';
import 'package:edubridge_app/screens/children_accessibility_overview_screen.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/speech_input_service.dart';
import 'package:edubridge_app/widgets/accessibility/emergency_button.dart';
import 'package:edubridge_app/widgets/accessibility/voice_draft_button.dart';
import 'package:edubridge_app/widgets/accessibility/word_prediction_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'speech_input_test.dart' show FakeRecognizer, FakeResult;

class _LanguageRecognizer extends FakeRecognizer implements LanguageSpeechRecognizer {
  String? selected;
  @override
  Future<String?> localeForLanguage(String language) async => '$language-test';
  @override
  Future<void> listen({required stt.SpeechListenOptions options,
      required void Function(SpeechRecognitionResult) onResult}) {
    selected = options.localeId;
    return super.listen(options: options, onResult: onResult);
  }
}
Future<void> host(WidgetTester tester, String language, Widget child) async {
  await tester.pumpWidget(MaterialApp(locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, body) => MediaQuery(data: MediaQuery.of(context).copyWith(
      textScaler: const TextScaler.linear(2)), child: body!), home: child));
  await tester.pumpAndSettle();
}
Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target); await tester.tap(target); await tester.pumpAndSettle();
}
void main() {
  testWidgets('interactive lesson follows UI direction while retaining authored answers through language changes', (tester) async {
    tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetDevicePixelRatio); addTearDown(tester.view.resetPhysicalSize);
    const lesson = InteractiveLesson(id:'original', subject:'arabic', title:'عنوان المعلم', objective:'هدف', steps:[
      LessonExplanation('intro','محتوى المعلم الأصلي'),
      LessonSingleChoice('q','اختر الحرف', [LessonOption('a','أ'), LessonOption('b','ب')], 'a'),
    ]);
    const player = InteractiveLessonPlayer(lesson: lesson);
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    await host(tester,'en',player);
    expect(Directionality.of(tester.element(find.byType(InteractiveLessonPlayer))), TextDirection.ltr);
    expect(find.text('محتوى المعلم الأصلي'), findsOneWidget);
    await tap(tester,find.text(en.practiceNext));
    await tap(tester,find.text('ب'));
    await tap(tester,find.text(en.practiceCheck));
    expect(find.text(en.practiceRetry), findsOneWidget);
    await host(tester,'ar',player);
    expect(find.text(ar.practiceRetry), findsOneWidget);
    expect(find.text('اختر الحرف'), findsOneWidget);
    await tap(tester,find.text(ar.practiceTryAgain));
    await tap(tester,find.text('أ'));
    await tap(tester,find.text(ar.practiceCheck));
    await tap(tester,find.text(ar.practiceFinish));
    await host(tester,'en',player);
    expect(find.text(en.practiceWellDone), findsOneWidget);
    await tap(tester,find.text(en.practiceRestart));
    expect(find.text('محتوى المعلم الأصلي'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('dictation selects language and discards late results after locale changes', (tester) async {
    final engine = _LanguageRecognizer();
    final service = SpeechInputService.forTesting(engine);
    final controller = TextEditingController(text:'مسودة');
    final widget = Scaffold(body:VoiceDraftButton(controller:controller, enabled:true, speechInput:service));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    await host(tester,'en',widget);
    await tap(tester,find.text(en.dictationWrite));
    expect(engine.selected,'en-test');
    final late = engine.result!;
    await host(tester,'ar',widget);
    late(FakeResult('stale'));
    await tester.pump();
    expect(controller.text,'مسودة');
    await tap(tester,find.text(ar.dictationWrite));
    expect(engine.selected,'ar-test');
    engine.result!(FakeResult('كلام أصلي'));
    await tester.pumpAndSettle();
    expect(controller.text,'مسودة كلام أصلي');
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
  testWidgets('word prediction localizes defaults and preserves custom words', (tester) async {
    final controller = TextEditingController(text:'wa');
    await host(tester,'en',Scaffold(body:WordPredictionBar(controller:controller,enabled:true)));
    expect(find.text('want'),findsOneWidget);
    await tap(tester,find.text('want'));
    expect(controller.text,'want');
    controller.text='أر';
    await host(tester,'ar',Scaffold(body:WordPredictionBar(controller:controller,enabled:true)));
    expect(find.text('أريد'),findsOneWidget);
    controller.text='cu';
    await host(tester,'en',Scaffold(body:WordPredictionBar(controller:controller,enabled:true,words:const ['custom'])));
    await tap(tester,find.text('custom'));
    expect(controller.text,'custom');
    await tester.pumpWidget(const SizedBox.shrink()); controller.dispose();
  });
  testWidgets('emergency dialogs localize and scroll without sending an external alert', (tester) async {
    AccessibilityService.instance.profile.value=const AccessibilityProfile(type:DisabilityType.none,sensoryCalmMode:true);
    addTearDown(AccessibilityService.instance.resetSession);
    tester.view.devicePixelRatio=1; tester.view.physicalSize=const Size(320,800);
    addTearDown(tester.view.resetDevicePixelRatio); addTearDown(tester.view.resetPhysicalSize);
    const widget=Scaffold(body:SingleChildScrollView(child:EmergencyButton(childName:'ليان')));
    final en=await AppLocalizations.delegate.load(const Locale('en'));
    final ar=await AppLocalizations.delegate.load(const Locale('ar'));
    await host(tester,'en',widget);
    await tap(tester,find.text(en.emergencySend));
    await host(tester,'ar',widget);
    expect(find.text(ar.emergencyConfirmBody('ليان')),findsOneWidget);
    await tap(tester,find.text(ar.cancel));
    await tap(tester,find.text(ar.emergencySend));
    // No child ID or phone numbers: only local instructions are exercised.
    await tap(tester,find.text(ar.emergencySendNow));
    await host(tester,'en',widget);
    expect(find.text(en.emergencyLocal),findsOneWidget);
    await tap(tester,find.text(en.emergencyUnderstood));
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('overview specialist gate remains active and translates retained errors', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final en=await AppLocalizations.delegate.load(const Locale('en'));
    final ar=await AppLocalizations.delegate.load(const Locale('ar'));
    const screen=ChildrenAccessibilityOverviewScreen();
    await host(tester,'en',screen);
    expect(find.text(en.overviewSpecialistOnly),findsOneWidget);
    await host(tester,'ar',screen);
    expect(find.text(ar.overviewSpecialistOnly),findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
