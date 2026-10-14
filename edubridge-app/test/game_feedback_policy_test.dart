import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/encouragement_service.dart';
import 'package:edubridge_app/screens/educational_games_screen.dart';
import 'package:edubridge_app/games/math_race_game.dart';
import 'package:edubridge_app/games/choice_learning_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final accessibility = AccessibilityService.instance;
  tearDown(accessibility.resetSession);

  test('automatic encouragement follows current speech and calm preferences', () async {
    var profile = const AccessibilityProfile(type: DisabilityType.none);
    final calls = <String>[];
    final encouragement = EncouragementService(profile: () => profile,
      speak: (text) async => calls.add('normal'),
      speakSlow: (text) async => calls.add('slow'));
    await encouragement.praiseGame();
    expect(calls, isEmpty);
    profile = profile.copyWith(autoReadOnTap: true, slowSpeech: true);
    await encouragement.praiseSuccess();
    expect(calls, ['slow']);
    profile = profile.copyWith(sensoryCalmMode: true);
    await encouragement.praiseStreak();
    await encouragement.praiseByName('محمود');
    expect(calls, ['slow']);
    profile = profile.copyWith(sensoryCalmMode: false, slowSpeech: false);
    await encouragement.praiseForDown();
    expect(calls, ['slow', 'normal']);
  });

  testWidgets('catalog rebuilds do not replay the route welcome', (tester) async {
    var speeches = 0;
    final encouragement = EncouragementService(
      profile: () => const AccessibilityProfile(type: DisabilityType.none, autoReadOnTap: true),
      speak: (_) async { speeches++; }, speakSlow: (_) async { speeches++; });
    await tester.pumpWidget(MaterialApp(home: EducationalGamesScreen(
      childName: 'محمود', encouragement: encouragement)));
    await tester.pump();
    expect(speeches, 1);
    await tester.pumpWidget(MaterialApp(home: EducationalGamesScreen(
      childName: 'محمود', age: 9, encouragement: encouragement)));
    await tester.pump();
    expect(speeches, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final profile in [
    const AccessibilityProfile(type: DisabilityType.none, unlimitedTime: true),
    const AccessibilityProfile(type: DisabilityType.none, noTimedInteractions: true),
    const AccessibilityProfile(type: DisabilityType.none, noTimers: true),
  ]) {
    testWidgets('math game preserves an untimed session ${profile.toJson()}', (tester) async {
      accessibility.profile.value = profile;
      await tester.pumpWidget(const MaterialApp(home: MathRaceGame(childName: 'محمود', age: 8)));
      await tester.pump(const Duration(seconds: 70));
      expect(find.text('✅ بدون وقت'), findsOneWidget);
      expect(find.text('إنهاء اللعب'), findsOneWidget);
      expect(find.textContaining('⏱️'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('math deadline follows chosen preferences rather than diagnosis and pauses in background', (tester) async {
    accessibility.profile.value = const AccessibilityProfile(type: DisabilityType.adhd);
    await tester.pumpWidget(const MaterialApp(home: MathRaceGame(childName: 'محمود', age: 8)));
    expect(find.text('⏱️ 60'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('⏱️ 59'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('⏱️ 59'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('⏱️ 58'), findsOneWidget);
    accessibility.profile.value = accessibility.profile.value.copyWith(unlimitedTime: true);
    await tester.pump(const Duration(seconds: 70));
    expect(find.text('✅ بدون وقت'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('game answer haptics respect calm mode and saved vibration preference', (tester) async {
    final vibrations = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') vibrations.add(call.arguments);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    accessibility.profile.value = const AccessibilityProfile(type: DisabilityType.none, vibrationAlerts: true,
      sensoryCalmMode: true, unlimitedTime: true);
    await tester.pumpWidget(const MaterialApp(home: MathRaceGame(childName: 'محمود', age: 8)));
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();
    expect(vibrations, isEmpty);
    accessibility.profile.value = accessibility.profile.value.copyWith(sensoryCalmMode: false);
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();
    expect(vibrations, ['HapticFeedbackType.mediumImpact']);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('choice games use child calm preferences without disabling explicit listening', (tester) async {
    final speech = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      speech.add(call);
      return 1;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    accessibility.applicationProfile.value = const AccessibilityProfile(type: DisabilityType.none);
    accessibility.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      sensoryCalmMode: true, slowSpeech: true);
    await tester.pumpWidget(const MaterialApp(home: ChoiceLearningGame(
      topic: LearningTopic.colors, childName: 'محمود', age: 6)));
    final switcher = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
    expect(switcher.duration, Duration.zero);
    await tester.ensureVisible(find.text('ابدأ اللعب'));
    await tester.tap(find.text('ابدأ اللعب'));
    await tester.pumpAndSettle();
    expect(speech.where((call) => call.method == 'speak'), isEmpty);
    await tester.ensureVisible(find.text('استمع للسؤال'));
    await tester.tap(find.text('استمع للسؤال'));
    await tester.pumpAndSettle();
    expect(speech.where((call) => call.method == 'speak'), isNotEmpty);
    expect(speech.where((call) => call.method == 'setSpeechRate').last.arguments, 0.30);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

}
