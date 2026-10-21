import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/reward_service.dart';
import 'package:edubridge_app/widgets/accessibility/audio_timer.dart';
import 'package:edubridge_app/widgets/accessibility/visual_timer.dart';
import 'package:edubridge_app/widgets/accessibility/visual_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _host(WidgetTester tester, String language, Widget body, {double scale = 1}) async {
  await tester.pumpWidget(MaterialApp(locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale)), child: child!), home: Scaffold(body: SingleChildScrollView(child: body))));
  await tester.pump();
  await tester.pump();
}
Future<void> _tap(WidgetTester tester, String text) async {
  final target = find.text(text);
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.tap(target.hitTestable());
  await tester.pump();
}
void main() {
  tearDown(AccessibilityService.instance.resetSession);
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$language visual timer at $scale preserves pause, resume and restart', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 800);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final s = await AppLocalizations.delegate.load(Locale(language));
        var finishes = 0;
        await _host(tester, language, VisualTimer(total: const Duration(seconds: 2),
          label: 'عنوان المؤلف', onFinished: () => finishes++), scale: scale);
        expect(find.text('عنوان المؤلف'), findsOneWidget);
        await _tap(tester, s.timerPause);
        await tester.pump(const Duration(seconds: 3));
        expect(finishes, 0);
        await _tap(tester, s.timerResume);
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(finishes, 1);
        expect(find.text(s.timerFinished), findsOneWidget);
        await _tap(tester, s.timerRestart);
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(finishes, 2);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
      testWidgets('$language audio timer at $scale keeps controls and canonical timing', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 800);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final s = await AppLocalizations.delegate.load(Locale(language));
        var finishes = 0;
        await _host(tester, language, AudioTimer(total: const Duration(seconds: 3),
          childName: 'محمود', onFinished: () => finishes++), scale: scale);
        expect(find.text(s.timerAudioTitle), findsOneWidget);
        await _tap(tester, s.timerStart);
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('0:02'), findsOneWidget);
        await _tap(tester, s.timerPause);
        await tester.pump(const Duration(seconds: 5));
        expect(finishes, 0);
        await _tap(tester, s.timerReset);
        expect(find.text('0:03'), findsOneWidget);
        await _tap(tester, s.timerStart);
        await tester.pump(const Duration(seconds: 3));
        expect(finishes, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
    testWidgets('$language default celebration and original custom message remain distinct', (tester) async {
      final s = await AppLocalizations.delegate.load(Locale(language));
      await _host(tester, language, const SizedBox(height: 400, child: Stack(children: [VisualCelebration(noMotion: true)])));
      expect(find.text(s.celebrationDefault), findsOneWidget);
      await _host(tester, language, const SizedBox(height: 400, child: Stack(children: [VisualCelebration(noMotion: true, message: 'رسالة المؤلف الأصلية')])));
      expect(find.text('رسالة المؤلف الأصلية'), findsOneWidget);
      expect(find.text(s.celebrationDefault), findsNothing);
    });
    testWidgets('$language untimed reward keeps original message until localized Continue', (tester) async {
      final s = await AppLocalizations.delegate.load(Locale(language));
      AccessibilityService.instance.profile.value = const AccessibilityProfile(
        type: DisabilityType.none, sensoryCalmMode: true, noTimedInteractions: true);
      late BuildContext screen;
      await _host(tester, language, Builder(builder: (context) { screen = context; return const Text('screen'); }));
      var done = false;
      final reward = RewardService.showReward(screen, message: 'أحسنت يا محمود', stars: 2).then((_) => done = true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(done, isFalse);
      expect(find.text('أحسنت يا محمود'), findsOneWidget);
      await _tap(tester, s.feedbackContinue);
      await reward;
      expect(done, isTrue);
    });
  }
  testWidgets('changing audio timer locale preserves remaining time and speaks the active language', (tester) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async { calls.add(call); return 1; });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    AccessibilityService.instance.profile.value = const AccessibilityProfile(type: DisabilityType.none, autoReadOnTap: true);
    const timer = AudioTimer(total: Duration(seconds: 5), childName: 'محمود');
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    await _host(tester, 'ar', timer);
    await _tap(tester, ar.timerStart);
    await tester.runAsync(() async { await Future<void>.delayed(Duration.zero); });
    await tester.pump(const Duration(seconds: 1));
    await _host(tester, 'en', timer);
    expect(find.text('0:04'), findsOneWidget);
    await _tap(tester, en.timerPause);
    await tester.runAsync(() async { await Future<void>.delayed(Duration.zero); });
    expect(calls.where((c) => c.method == 'setLanguage').last.arguments, 'en');
    final speech = calls.lastWhere((c) => c.method == 'speak').arguments;
    expect(speech is Map ? speech['text'] : speech, en.timerPausedSpeech);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
