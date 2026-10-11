import '../services/accessibility_service.dart';

/// Shared preferences for optional feedback, without disabling explicit speech.
class AdaptiveFeedbackPolicy {
  final AccessibilityProfile profile;
  final bool systemReduceMotion;

  const AdaptiveFeedbackPolicy(this.profile, {this.systemReduceMotion = false});

  bool get allowMotion => !systemReduceMotion && !profile.sensoryCalmMode &&
      !profile.reducedAnimations && !profile.noFlashing;
  bool get allowFlash => allowMotion && profile.flashAlerts;
  bool get allowAutomaticSpeech => profile.autoReadOnTap &&
      !profile.sensoryCalmMode;
  bool get allowHaptics => profile.vibrationAlerts && !profile.sensoryCalmMode;
}
