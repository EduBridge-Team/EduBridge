import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/widgets/accessibility/visual_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AccessibilityService.instance.resetSession());

  testWidgets('reduced system animation preserves actual countdown time', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    var finishes = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: VisualTimer(total: const Duration(seconds: 10), onFinished: () => finishes++)))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(finishes, 0);
    await tester.pump(const Duration(seconds: 9));
    expect(finishes, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final profile in [
    const AccessibilityProfile(type: DisabilityType.deaf),
    const AccessibilityProfile(type: DisabilityType.none, vibrationAlerts: true),
    const AccessibilityProfile(type: DisabilityType.deaf, vibrationAlerts: true, sensoryCalmMode: true),
  ]) {
    testWidgets('timer completion respects chosen haptic preference ${profile.type} ${profile.sensoryCalmMode}', (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      AccessibilityService.instance.profile.value = profile;
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: VisualTimer(total: Duration(seconds: 1)))));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(calls, profile.vibrationAlerts && !profile.sensoryCalmMode ? ['HapticFeedbackType.mediumImpact'] : isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
