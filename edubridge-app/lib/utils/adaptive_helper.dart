// lib/utils/adaptive_helper.dart
// المساعد الموحّد — يقرأ بروفايل الطفل ويعطيك كل الإعدادات الفعلية
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../services/tts_service.dart';

class AdaptiveHelper {
  AdaptiveHelper._();

  /// البروفايل النشط حالياً
  static AccessibilityProfile get profile =>
      AccessibilityService.instance.profile.value;

  /// حجم النص الأساسي
  static double get bodyFontSize {
    final p = profile;
    if (p.type == DisabilityType.blind) return 24;
    if (p.type == DisabilityType.downSyndrome) return 22;
    if (p.extraLargeTouchTargets) return 20;
    if (p.type == DisabilityType.mildIntellectual) return 20;
    if (p.type == DisabilityType.motorDisability) return 20;
    if (p.type == DisabilityType.autismSevere) return 22;
    if (p.type == DisabilityType.multipleDisabilities) return 22;
    if (p.type == DisabilityType.deaf) return 18;
    if (p.type == DisabilityType.stuttering) return 18;
    if (p.type == DisabilityType.speechDisorders) return 18;
    return 16;
  }

  /// حجم العنوان الرئيسي
  static double get titleFontSize {
    final p = profile;
    if (p.type == DisabilityType.blind) return 32;
    if (p.type == DisabilityType.downSyndrome) return 28;
    if (p.extraLargeTouchTargets) return 26;
    if (p.type == DisabilityType.mildIntellectual) return 26;
    if (p.type == DisabilityType.autismSevere) return 26;
    return 22;
  }

  /// حجم العنوان الفرعي
  static double get subtitleFontSize {
    final p = profile;
    if (p.type == DisabilityType.blind) return 26;
    if (p.extraLargeTouchTargets) return 22;
    return 18;
  }

  /// ارتفاع الزر
  static double get buttonHeight {
    if (profile.extraLargeTouchTargets) return 88;
    if (profile.type == DisabilityType.blind) return 80;
    if (profile.type == DisabilityType.downSyndrome) return 88;
    if (profile.type == DisabilityType.motorDisability) return 80;
    if (profile.type == DisabilityType.mildIntellectual) return 72;
    if (profile.type == DisabilityType.autismSevere) return 72;
    return 56;
  }

  /// حجم الأيقونة
  static double get iconSize {
    if (profile.extraLargeTouchTargets) return 44;
    if (profile.type == DisabilityType.blind) return 48;
    if (profile.type == DisabilityType.downSyndrome) return 44;
    if (profile.type == DisabilityType.mildIntellectual) return 40;
    return 28;
  }

  /// حجم الأفاتار
  static double get avatarSize {
    if (profile.extraLargeTouchTargets) return 72;
    if (profile.type == DisabilityType.downSyndrome) return 72;
    if (profile.type == DisabilityType.blind) return 68;
    return 56;
  }

  /// المسافة بين العناصر
  static double get spacing {
    if (profile.extraLargeTouchTargets) return 20;
    if (profile.type == DisabilityType.blind) return 20;
    if (profile.type == DisabilityType.downSyndrome) return 20;
    if (profile.type == DisabilityType.motorDisability) return 20;
    return 12;
  }

  /// حواف الكروت
  static double get cardRadius {
    if (profile.type == DisabilityType.downSyndrome) return 32;
    if (profile.extraLargeTouchTargets) return 24;
    if (profile.type == DisabilityType.autismMild) return 16;
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

  static Duration get animationDuration {
    if (profile.reducedAnimations || profile.noFlashing) return Duration.zero;
    if (profile.type == DisabilityType.blind) {
      return const Duration(milliseconds: 100);
    }
    if (profile.type == DisabilityType.autismMild ||
        profile.type == DisabilityType.autismSevere) {
      return const Duration(milliseconds: 500);
    }
    return const Duration(milliseconds: 250);
  }

  static Curve get animationCurve {
    if (profile.reducedAnimations) return Curves.linear;
    return Curves.easeInOut;
  }

  // ═══════════════════════════════════════════════════════════
  //  🔊 الصوت
  // ═══════════════════════════════════════════════════════════

  /// هل نقرأ النص عند اللمس؟
  static bool get shouldReadOnTap => profile.autoReadOnTap;

  /// هل نستخدم النطق البطيء؟
  static bool get useSlowSpeech => profile.slowSpeech;

  /// نطق نص حسب إعدادات البروفايل
  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    if (useSlowSpeech) {
      await TtsService.instance.speakLineSlow(text);
    } else {
      await TtsService.instance.speakLine(text);
    }
  }

  /// اهتزاز عند اللمس (للصمّ)
  static Future<void> hapticFeedback() async {
    if (profile.vibrationAlerts) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// هل الأنيميشن مفعّل؟
  static bool get isAnimated => !profile.reducedAnimations && !profile.noFlashing;
}