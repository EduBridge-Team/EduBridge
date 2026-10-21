// lib/utils/adaptive_helper.dart
// المساعد الموحّد — يقرأ بروفايل الطفل ويعطيك كل الإعدادات الفعلية
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../services/tts_service.dart';
import 'adaptive_feedback_policy.dart';

class AdaptiveHelper {
  AdaptiveHelper._();

  /// البروفايل النشط حالياً
  static AccessibilityProfile get profile =>
      AccessibilityService.instance.profile.value;

  /// حجم النص الأساسي
  static double get bodyFontSize {
    final p = profile;
    if (p.extraLargeTouchTargets) return 20;
    return 16;
  }

  /// حجم العنوان الرئيسي
  static double get titleFontSize {
    final p = profile;
    if (p.extraLargeTouchTargets) return 26;
    return 22;
  }

  /// حجم العنوان الفرعي
  static double get subtitleFontSize {
    final p = profile;
    if (p.extraLargeTouchTargets) return 22;
    return 18;
  }

  /// ارتفاع الزر
  static double get buttonHeight {
    if (profile.extraLargeTouchTargets) return 88;
    return 56;
  }

  /// حجم الأيقونة
  static double get iconSize {
    if (profile.extraLargeTouchTargets) return 44;
    return 28;
  }

  /// حجم الأفاتار
  static double get avatarSize {
    if (profile.extraLargeTouchTargets) return 72;
    return 56;
  }

  /// المسافة بين العناصر
  static double get spacing {
    if (profile.extraLargeTouchTargets) return 20;
    return 12;
  }

  /// حواف الكروت
  static double get cardRadius {
    if (profile.extraLargeTouchTargets) return 24;
    return 20;
  }

  /// سماكة الحدود
  static double get borderWidth {
    if (profile.highContrast) return 2.5;
    return 1.5;
  }


  /// لون الخلفية الرئيسي
  static Color surfaceColor(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;

  /// لون النص الرئيسي
  static Color textColor(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  /// لون التمييز
  static Color accentColor(BuildContext context) => Theme.of(context).colorScheme.primary;

  /// لون الكارت
  static Color cardColor(BuildContext context) => Theme.of(context).cardColor;

  // ═══════════════════════════════════════════════════════════
  //  ⚡ الأنيميشن
  // ═══════════════════════════════════════════════════════════

  static Duration get animationDuration => AdaptiveFeedbackPolicy(profile).allowMotion
      ? const Duration(milliseconds: 250) : Duration.zero;

  static Curve get animationCurve => isAnimated ? Curves.easeInOut : Curves.linear;

  // ═══════════════════════════════════════════════════════════
  //  🔊 الصوت
  // ═══════════════════════════════════════════════════════════

  /// هل نقرأ النص عند اللمس؟
  static bool get shouldReadOnTap => AdaptiveFeedbackPolicy(profile).allowAutomaticSpeech;

  /// هل نستخدم النطق البطيء؟
  static bool get useSlowSpeech => profile.slowSpeech;

  /// نطق نص حسب إعدادات البروفايل
  static Future<void> speak(String text, {String languageCode = 'ar'}) async {
    if (text.trim().isEmpty) return;
    if (useSlowSpeech) {
      await TtsService.instance.speakLineSlow(text, languageCode: languageCode);
    } else {
      await TtsService.instance.speakLine(text, languageCode: languageCode);
    }
  }

  /// اهتزاز عند اللمس (للصمّ)
  static Future<void> hapticFeedback() async {
    if (AdaptiveFeedbackPolicy(profile).allowHaptics) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// هل الأنيميشن مفعّل؟
  static bool get isAnimated => AdaptiveFeedbackPolicy(profile).allowMotion;
}