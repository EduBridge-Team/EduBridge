// lib/utils/adaptive_theme.dart
// محوّل البروفايل إلى خصائص بصرية ملموسة
//
// ═══════════════════════════════════════════════════════════
//  🎨 مبدأ التصميم:
//  - كل الإعاقات تستخدم ألوان هوية الشعار (أزرق + تركوازي)
//  - الاستثناء الوحيد: التباين العالي (للكفيف) — إلزامي للقراءة
//  - الأحجام والحركات تتغير حسب الإعاقة (وظيفي)
//  - الألوان ثابتة (هوية بصرية)
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../theme.dart';

class AdaptiveVisuals {
  final Color accentColor;
  final Color surfaceColor;
  final double cardRadius;
  final double buttonHeight;
  final double iconSize;
  final double titleFontSize;
  final double bodyFontSize;
  final double spacing;
  final Duration animationSpeed;
  final String profileLabel;
  final String profileEmoji;
  final Color profileBadgeColor;

  const AdaptiveVisuals({
    required this.accentColor,
    required this.surfaceColor,
    required this.cardRadius,
    required this.buttonHeight,
    required this.iconSize,
    required this.titleFontSize,
    required this.bodyFontSize,
    required this.spacing,
    required this.animationSpeed,
    required this.profileLabel,
    required this.profileEmoji,
    required this.profileBadgeColor,
  });

  // ═══════════════════════════════════════════════════════════
  //  من البروفايل → إلى خصائص بصرية
  // ═══════════════════════════════════════════════════════════
  static AdaptiveVisuals fromProfile(AccessibilityProfile p) {
    // ─── 1. حالة الكفيف: تباين عالٍ إلزامي (استثناء وحيد) ───
    if (p.highContrast || p.type == DisabilityType.blind) {
      return const AdaptiveVisuals(
        accentColor: Color(0xFFFFD400),        // أصفر — إلزامي للقراءة
        surfaceColor: Color(0xFF000000),       // أسود
        cardRadius: 12,
        buttonHeight: 80,
        iconSize: 48,
        titleFontSize: 28,
        bodyFontSize: 22,
        spacing: 20,
        animationSpeed: Duration(milliseconds: 100),
        profileLabel: 'وضع التباين العالي',
        profileEmoji: '👁️',
        profileBadgeColor: Color(0xFFFFD400),
      );
    }

    // ─── 2. جميع الإعاقات الأخرى: ألوان هوية الشعار ───
    return AdaptiveVisuals(
      // ═══ الألوان من هوية EduBridge ═══
      accentColor: _accentFor(p),
      surfaceColor: _surfaceFor(p),
      profileBadgeColor: _accentFor(p),

      // ═══ الأحجام تتغير حسب الإعاقة (وظيفي) ═══
      cardRadius: _radiusFor(p),
      buttonHeight: _buttonHeightFor(p),
      iconSize: _iconSizeFor(p),
      titleFontSize: _titleFontFor(p),
      bodyFontSize: _bodyFontFor(p),
      spacing: _spacingFor(p),
      animationSpeed: _animationFor(p),

      // ═══ التسمية والرمز ═══
      profileLabel: _labelFor(p),
      profileEmoji: disabilityEmojis[p.type] ?? '⚪',
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  🎨 الألوان — من هوية الشعار
  // ═══════════════════════════════════════════════════════════
  static Color _accentFor(AccessibilityProfile p) {
    // وضع الهدوء الحسي: تركوازي فاتح (ناعم للعين)
    if (p.sensoryCalmMode) return AppColors.brandTealLight;

    // الإعاقات السمعية والنطقية: تركوازي الشعار
    if (p.type == DisabilityType.deaf ||
        p.type == DisabilityType.stuttering ||
        p.type == DisabilityType.speechDisorders) {
      return AppColors.brandTealDeep;
    }

    // ADHD: تركوازي (دافئ ومحفّز — من الهوية)
    if (p.type == DisabilityType.adhd) return AppColors.brandTeal;

    // الباقي: أزرق الشعار
    return AppColors.brandBlue;
  }

  static Color _surfaceFor(AccessibilityProfile p) {
    // وضع الهدوء الحسي (توحد): أزرق فاتح جداً
    if (p.sensoryCalmMode) return AppColors.tintTeal;

    // الداون: أخضر فاتح من الهوية
    if (p.type == DisabilityType.downSyndrome) return AppColors.tintGreen;

    // التوحد: أزرق فاتح
    if (p.type == DisabilityType.autismMild ||
        p.type == DisabilityType.autismSevere) {
      return AppColors.tintTeal;
    }

    // الباقي: الكريمي الرسمي
    return AppColors.cream;
  }

  // ═══════════════════════════════════════════════════════════
  //  📐 الأحجام — تتغير حسب الإعاقة
  // ═══════════════════════════════════════════════════════════
  static double _buttonHeightFor(AccessibilityProfile p) {
    // أزرار ضخمة جداً: داون، إعاقات متعددة، إعاقة ذهنية
    if (p.extraLargeTouchTargets ||
        p.type == DisabilityType.downSyndrome ||
        p.type == DisabilityType.multipleDisabilities ||
        p.type == DisabilityType.mildIntellectual) {
      return 88;
    }
    // أزرار كبيرة: إعاقات حركية، توحد شديد
    if (p.type == DisabilityType.motorDisability ||
        p.type == DisabilityType.autismSevere) {
      return 80;
    }
    // ADHD: متوسطة (حركة نشطة)
    if (p.type == DisabilityType.adhd) return 60;
    // الافتراضي
    return 56;
  }

  static double _iconSizeFor(AccessibilityProfile p) {
    if (p.extraLargeTouchTargets ||
        p.type == DisabilityType.downSyndrome ||
        p.type == DisabilityType.multipleDisabilities) {
      return 44;
    }
    if (p.type == DisabilityType.motorDisability ||
        p.type == DisabilityType.mildIntellectual) {
      return 40;
    }
    if (p.type == DisabilityType.autismSevere ||
        p.type == DisabilityType.deaf) {
      return 36;
    }
    return 28;
  }

  static double _titleFontFor(AccessibilityProfile p) {
    if (p.extraLargeTouchTargets ||
        p.type == DisabilityType.downSyndrome) {
      return 26;
    }
    if (p.type == DisabilityType.autismSevere ||
        p.type == DisabilityType.mildIntellectual ||
        p.type == DisabilityType.multipleDisabilities) {
      return 24;
    }
    if (p.type == DisabilityType.deaf ||
        p.type == DisabilityType.motorDisability) {
      return 22;
    }
    return 20;
  }

  static double _bodyFontFor(AccessibilityProfile p) {
    if (p.extraLargeTouchTargets ||
        p.type == DisabilityType.downSyndrome) {
      return 22;
    }
    if (p.type == DisabilityType.autismSevere ||
        p.type == DisabilityType.mildIntellectual ||
        p.type == DisabilityType.multipleDisabilities) {
      return 20;
    }
    if (p.type == DisabilityType.deaf ||
        p.type == DisabilityType.motorDisability) {
      return 18;
    }
    return 16;
  }

  static double _radiusFor(AccessibilityProfile p) {
    if (p.type == DisabilityType.downSyndrome) return 32;
    if (p.extraLargeTouchTargets ||
        p.type == DisabilityType.mildIntellectual) {
      return 28;
    }
    if (p.type == DisabilityType.motorDisability ||
        p.type == DisabilityType.multipleDisabilities) {
      return 24;
    }
    if (p.type == DisabilityType.adhd) return 24;
    return 20;
  }

  static double _spacingFor(AccessibilityProfile p) {
    if (p.extraLargeTouchTargets ||
        p.type == DisabilityType.downSyndrome ||
        p.type == DisabilityType.motorDisability ||
        p.type == DisabilityType.mildIntellectual) {
      return 20;
    }
    if (p.type == DisabilityType.autismMild ||
        p.type == DisabilityType.autismSevere) {
      return 16;
    }
    return 14;
  }

  // ═══════════════════════════════════════════════════════════
  //  ⚡ الحركة — تتغير حسب الإعاقة
  // ═══════════════════════════════════════════════════════════
  static Duration _animationFor(AccessibilityProfile p) {
    // حركة هادئة جداً: توحد، داون، صرع
    if (p.reducedAnimations ||
        p.type == DisabilityType.downSyndrome ||
        p.type == DisabilityType.multipleDisabilities) {
      return const Duration(milliseconds: 180);
    }
    // حركة هادئة: توحد، صرع
    if (p.type == DisabilityType.autismMild ||
        p.type == DisabilityType.autismSevere) {
      return const Duration(milliseconds: 500);
    }
    if (p.type == DisabilityType.epilepsy) {
      return const Duration(milliseconds: 400);
    }
    // الافتراضي
    return const Duration(milliseconds: 250);
  }

  // ═══════════════════════════════════════════════════════════
  //  🏷️ التسمية العربية لكل حالة
  // ═══════════════════════════════════════════════════════════
  static String _labelFor(AccessibilityProfile p) {
    switch (p.type) {
      case DisabilityType.adhd:
        return 'وضع التركيز';
      case DisabilityType.autismMild:
      case DisabilityType.autismSevere:
        return 'وضع هادئ';
      case DisabilityType.downSyndrome:
        return 'وضع مبسّط';
      case DisabilityType.blind:
        return 'تباين عالٍ';
      case DisabilityType.deaf:
        return 'تنبيهات بصرية';
      case DisabilityType.stuttering:
        return 'نطق بطيء';
      case DisabilityType.speechDisorders:
        return 'دعم النطق';
      case DisabilityType.mildIntellectual:
        return 'خطوة بخطوة';
      case DisabilityType.colorBlindness:
        return 'رموز مميزة';
      case DisabilityType.epilepsy:
        return 'وضع آمن';
      case DisabilityType.motorDisability:
        return 'تحكم مساعد';
      case DisabilityType.multipleDisabilities:
        return 'وضع شامل';
      case DisabilityType.other:
        return p.customDisabilityName ?? 'وضع مخصّص';
      case DisabilityType.none:
        return 'الوضع العادي';
    }
  }
}