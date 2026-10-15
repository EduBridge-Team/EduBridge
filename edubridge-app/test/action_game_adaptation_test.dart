import 'package:edubridge_app/games/quick_action_game.dart';
import 'package:edubridge_app/games/rhythm_game.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = AccessibilityService.instance;
  tearDown(service.resetSession);

  for (final setting in ['noTimers', 'unlimitedTime', 'noTimedInteractions']) {
    testWidgets('quick action remains playable without deadline: $setting', (tester) async {
      service.profile.value = AccessibilityProfile(type: DisabilityType.none,
        noTimers: setting == 'noTimers', unlimitedTime: setting == 'unlimitedTime',
        noTimedInteractions: setting == 'noTimedInteractions');
      await tester.pumpWidget(const MaterialApp(home: QuickActionGame(childName: 'نور')));
      await tester.pump(const Duration(seconds: 35));
      expect(find.text('بدون وقت — خذ راحتك'), findsOneWidget);
      expect(find.text('إنهاء اللعب'), findsOneWidget);
      await tester.ensureVisible(find.text('فعلتها!'));
      await tester.tap(find.text('فعلتها!'));
      await tester.pump();
      expect(find.text('أحسنت!'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('quick action countdown pauses in background', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QuickActionGame(childName: 'نور')));
    expect(find.text('30'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('30'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('29'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('calm quick action suppresses the scale animation', (tester) async {
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none, sensoryCalmMode: true);
    await tester.pumpWidget(const MaterialApp(home: QuickActionGame(childName: 'نور')));
    final animation = tester.widget<TweenAnimationBuilder<double>>(find.byType(TweenAnimationBuilder<double>));
    expect(animation.duration, Duration.zero);
    expect(animation.tween.begin, 1);
    expect(animation.tween.end, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('untimed rhythm retains its word and supports manual continuation', (tester) async {
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none, noTimedInteractions: true,
      extraLargeTouchTargets: true, sensoryCalmMode: true);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: RhythmGame(childName: 'نور')));
    await tester.ensureVisible(find.text('ابدأ'));
    await tester.tap(find.text('ابدأ'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('الكلمة 1 من 8'), findsOneWidget);
    await tester.ensureVisible(find.text('متابعة'));
    await tester.tap(find.text('متابعة'));
    await tester.pump();
    expect(find.text('الكلمة 2 من 8'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('الكلمة 2 من 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('normal rhythm advances automatically and pause retains the word', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RhythmGame(childName: 'نور')));
    await tester.ensureVisible(find.text('ابدأ'));
    await tester.tap(find.text('ابدأ'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('الكلمة 2 من 8'), findsOneWidget);
    await tester.tap(find.byTooltip('إيقاف مؤقت'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('الكلمة 2 من 8'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
