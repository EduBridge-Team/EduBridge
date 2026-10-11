import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/utils/adaptive_feedback_policy.dart';

void main() {
  test('calm mode overrides optional flash, speech and vibration', () {
    const feedback = AdaptiveFeedbackPolicy(AccessibilityProfile(
      type: DisabilityType.none, sensoryCalmMode: true,
      flashAlerts: true, autoReadOnTap: true, vibrationAlerts: true,
    ));
    expect(feedback.allowMotion, isFalse);
    expect(feedback.allowFlash, isFalse);
    expect(feedback.allowAutomaticSpeech, isFalse);
    expect(feedback.allowHaptics, isFalse);
  });

  test('system reduced motion preserves explicit sound and haptic choices', () {
    const feedback = AdaptiveFeedbackPolicy(AccessibilityProfile(
      type: DisabilityType.none, flashAlerts: true,
      autoReadOnTap: true, vibrationAlerts: true,
    ), systemReduceMotion: true);
    expect(feedback.allowMotion, isFalse);
    expect(feedback.allowFlash, isFalse);
    expect(feedback.allowAutomaticSpeech, isTrue);
    expect(feedback.allowHaptics, isTrue);
  });
}
