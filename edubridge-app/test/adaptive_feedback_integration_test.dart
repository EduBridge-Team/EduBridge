import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/reward_service.dart';
import 'package:edubridge_app/widgets/accessibility/audio_timer.dart';
import 'package:edubridge_app/widgets/accessibility/emergency_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = AccessibilityService.instance;
  tearDown(service.resetSession);

  testWidgets('audio timer freezes in background and finishes only once', (tester) async {
    var finishes = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AudioTimer(
      total: const Duration(seconds: 3), childName: 'محمود',
      onFinished: () => finishes++))));
    await tester.tap(find.text('ابدأ'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0:02'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(finishes, 0);
    expect(find.text('0:02'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect(finishes, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(finishes, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('changing to unlimited time cancels the audio deadline', (tester) async {
    var finishes = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AudioTimer(
      total: const Duration(seconds: 2), childName: 'محمود',
      onFinished: () => finishes++))));
    await tester.tap(find.text('ابدأ'));
    service.profile.value = service.profile.value.copyWith(unlimitedTime: true);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('المؤقّت السمعي'), findsNothing);
    expect(finishes, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('calm audio timer never starts automatic speech', (tester) async {
    final speech = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      speech.add(call);
      return 1;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      autoReadOnTap: true, sensoryCalmMode: true);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AudioTimer(
      total: Duration(seconds: 2), childName: 'محمود'))));
    await tester.tap(find.text('ابدأ'));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('إعادة'));
    await tester.pump();
    expect(speech, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('audio countdown pauses while another route covers it', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    var finishes = 0;
    await tester.pumpWidget(MaterialApp(navigatorKey: navigator,
      home: Scaffold(body: AudioTimer(total: const Duration(seconds: 10),
        childName: 'محمود', onFinished: () => finishes++))));
    await tester.tap(find.text('ابدأ'));
    await tester.pump(const Duration(seconds: 1));
    final covered = navigator.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('صفحة أخرى'))));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 20));
    expect(finishes, 0);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await covered;
    expect(find.text('0:09'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('untimed calm reward remains visible until Continue', (tester) async {
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      noTimedInteractions: true, sensoryCalmMode: true);
    late BuildContext screen;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      screen = context;
      return const Scaffold(body: Text('الدرس'));
    })));
    var dismissed = false;
    final reward = RewardService.showReward(screen, message: 'أحسنت', stars: 2)
      .then((_) => dismissed = true);
    await tester.pump();
    final scale = tester.widget<ScaleTransition>(find.byType(ScaleTransition).last);
    expect(scale.scale.value, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('أحسنت'), findsOneWidget);
    expect(dismissed, isFalse);
    await tester.tap(find.text('متابعة'));
    await tester.pump();
    await reward;
    expect(dismissed, isTrue);
    expect(find.text('أحسنت'), findsNothing);
  });

  testWidgets('system reduced motion produces a static timed reward', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    late BuildContext screen;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      screen = context;
      return const Scaffold();
    })));
    final reward = RewardService.showReward(screen, message: 'تمام');
    await tester.pump();
    final scale = tester.widget<ScaleTransition>(find.byType(ScaleTransition).last);
    expect(scale.scale.value, 1);
    await tester.pump(const Duration(seconds: 3));
    await reward;
    await tester.pump();
    expect(find.text('تمام'), findsNothing);
  });

  testWidgets('cancelling emergency confirmation never vibrates or sends', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    service.profile.value = const AccessibilityProfile(type: DisabilityType.none, vibrationAlerts: true);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: EmergencyButton(childName: 'محمود'))));
    await tester.tap(find.text('إرسال تنبيه طوارئ')); 
    await tester.pumpAndSettle();
    expect(find.text('تأكيد الطوارئ'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(calls.where((call) => call.method == 'HapticFeedback.vibrate'), isEmpty);
  });
}
