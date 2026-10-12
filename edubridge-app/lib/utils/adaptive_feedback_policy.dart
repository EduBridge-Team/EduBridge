import '../services/accessibility_service.dart';

/// Shared preferences for optional feedback, without disabling explicit speech.
class AdaptiveFeedbackPolicy {
  final AccessibilityProfile profile;
  final bool systemReduceMotion;

  const AdaptiveFeedbackPolicy(this.profile, {this.systemReduceMotion = false});

  // Hide clocks without treating every time preference as the same feature.
  bool get showCountdown => !profile.noTimers && !profile.noTimedInteractions;
  bool get allowTaskDeadline => showCountdown && !profile.unlimitedTime;
  bool get allowAutoDismiss => !profile.noTimedInteractions;

  bool get allowMotion => !systemReduceMotion && !profile.sensoryCalmMode &&
      !profile.reducedAnimations && !profile.noFlashing;
  bool get allowFlash => allowMotion && profile.flashAlerts;
  bool get allowAutomaticSpeech => profile.autoReadOnTap &&
      !profile.sensoryCalmMode;
  bool get allowHaptics => profile.vibrationAlerts && !profile.sensoryCalmMode;
}
