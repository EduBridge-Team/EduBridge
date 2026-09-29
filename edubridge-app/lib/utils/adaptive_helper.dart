// lib/utils/adaptive_helper.dart
// المساعد الموحّد — يقرأ بروفايل الطفل ويعطيك كل الإعدادات الفعلية
//
// ═══════════════════════════════════════════════════════════
//  🎨 مبدأ التصميم:
//  - الألوان: من هوية الشعار (أزرق + تركوازي)
//  - الاستثناء: التباين العالي (للكفيف) — أصفر + أسود
//  - الأحجام والحركات: تتغير حسب الإعاقة (وظيفي)
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';

class AdaptiveHelper {
  AdaptiveHelper._();

  /// البروفايل النشط حالياً
  static AccessibilityProfile get profile =>
      AccessibilityService.instance.profile.value;

  // ═══════════════════════════════════════════════════════════
  //  📐 الأحجام — تتغير حسب الإعاقة
  // ═══════════════════════════════════════════════════════════

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
    final p = profile;
    if (p.extraLargeTouchTargets) return 88;
    if (p.type == DisabilityType.blind) return 80;
    if (p.type == DisabilityType.downSyndrome) return 88;
    if (p.type == DisabilityType.motorDisability) return 80;
    if (p.type == DisabilityType.mildIntellectual) return 72;
    if (p.type == DisabilityType.autismSevere) return 72;
    return 56;
  }

  /// حجم الأيقونة
  static double get iconSize {
    final p = profile;
    if (p.extraLargeTouchTargets) return 44;
    if (p.type == DisabilityType.blind) return 48;
    if (p.type == DisabilityType.downSyndrome) return 44;
    if (p.type == DisabilityType.mildIntellectual) return 40;
    return 28;
  }

  /// حجم الأفاتار
  static double get avatarSize {
    final p = profile;
    if (p.extraLargeTouchTargets) return 72;
    if (p.type == DisabilityType.downSyndrome) return 72;
    if (p.type == DisabilityType.blind) return 68;
    return 56;
  }

  /// المسافة بين العناصر
  static double get spacing {
    final p = profile;
    if (p.extraLargeTouchTargets) return 20;
    if (p.type == DisabilityType.blind) return 20;
    if (p.type == DisabilityType.downSyndrome) return 20;
    if (p.type == DisabilityType.motorDisability) return 20;
    return 12;
  }

  /// حواف الكروت
  static double get cardRadius {
    final p = profile;
    if (p.type == DisabilityType.downSyndrome) return 32;
    if (p.extraLargeTouchTargets) return 24;
    if (p.type == DisabilityType.autismMild) return 16;
    return 20;
  }

  /// سماكة الحدود
  static double get borderWidth {
    if (profile.highContrast) return 2.5;
    return 1.5;
  }

  // ═══════════════════════════════════════════════════════════
  //  🎨 الألوان — من هوية الشعار (استثناء واحد للكفيف)
  // ═══════════════════════════════════════════════════════════

  /// لون التمييز — ثابت من هوية الشعار
  /// الاستثناء الوحيد: التباين العالي (للكفيف) — أصفر للقراءة
  static Color accentColor(BuildContext context) {
    final p = profile;

    // ═══ استثناء إلزامي: الكفيف (أصفر على أسود)
    if (p.highContrast || p.type == DisabilityType.blind) {
      return const Color(0xFFFFD400);
    }

    // ═══ الباقي: ألوان الشعار الموحّدة ═══
    // وضع الهدوء الحسي: تركوازي فاتح
    if (p.sensoryCalmMode) return AppColors.brandTealLight;

    // ADHD: تركوازي (محفّز وهادئ)
    if (p.type == DisabilityType.adhd) return AppColors.brandTeal;

    // إعاقات سمعية/نطقية/حركية: تركوازي داكن
    if (p.type == DisabilityType.deaf ||
        p.type == DisabilityType.stuttering ||
        p.type == DisabilityType.speechDisorders ||
        p.type == DisabilityType.motorDisability) {
      return AppColors.brandTealDeep;
    }

    // الباقي: أزرق الشعار
    return AppColors.brandBlue;
  }

  /// لون الخلفية — خلفيات فاتحة من الهوية
  static Color surfaceColor(BuildContext context) {
    final p = profile;

    // ═══ استثناء إلزامي: الكفيف (أسود)
    if (p.highContrast || p.type == DisabilityType.blind) {
      return Colors.black;
    }

    // ═══ الباقي: خلفيات فاتحة من الهوية ═══
    // وضع الهدوء الحسي (توحد): أزرق فاتح جداً
    if (p.sensoryCalmMode) return AppColors.tintTeal;

    // الداون: أخضر فاتح
    if (p.type == DisabilityType.downSyndrome) return AppColors.tintGreen;

    // التوحد: أزرق فاتح
    if (p.type == DisabilityType.autismMild ||
        p.type == DisabilityType.autismSevere) {
      return AppColors.tintTeal;
    }

    // الباقي: كريمي الشعار
    return AppColors.cream;
  }

  /// لون النص الرئيسي
  static Color textColor(BuildContext context) {
    final p = profile;

    if (p.highContrast || p.type == DisabilityType.blind) {
      return Colors.white;
    }

    return Theme.of(context).colorScheme.onSurface;
  }

  /// لون الكارت
  static Color cardColor(BuildContext context) {
    final p = profile;

    // ═══ استثناء إلزامي: الكفيف ═══
    if (p.highContrast || p.type == DisabilityType.blind) {
      return const Color(0xFF1A1A1A);
    }

    // الباقي: أبيض
    return Colors.white;
  }

  // ═══════════════════════════════════════════════════════════
  //  ⚡ الأنيميشن
  // ═══════════════════════════════════════════════════════════

  static Duration get animationDuration {
    final p = profile;
    if (p.reducedAnimations) return const Duration(milliseconds: 80);
    if (p.type == DisabilityType.blind) {
      return const Duration(milliseconds: 100);
    }
    if (p.type == DisabilityType.autismMild ||
        p.type == DisabilityType.autismSevere) {
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

  /// اهتزاز عند اللمس (للصمّ والكفيف)
  static Future<void> hapticFeedback() async {
    final p = profile;
    if (p.vibrationAlerts ||
        p.type == DisabilityType.deaf ||
        p.type == DisabilityType.blind) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// هل الأنيميشن مفعّل؟
  static bool get isAnimated => !profile.reducedAnimations;
}