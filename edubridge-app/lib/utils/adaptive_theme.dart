// محوّل البروفايل إلى خصائص بصرية ملموسة
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

  static AdaptiveVisuals fromProfile(AccessibilityProfile p) {
    switch (p.type) {
      case DisabilityType.adhd:
        return const AdaptiveVisuals(
          accentColor: Color(0xFFF2842B),
          surfaceColor: Color(0xFFFFF8EE),
          cardRadius: 24,
          buttonHeight: 60,
          iconSize: 30,
          titleFontSize: 20,
          bodyFontSize: 16,
          spacing: 14,
          animationSpeed: Duration(milliseconds: 250),
          profileLabel: 'وضع فرط الحركة',
          profileEmoji: '⚡',
          profileBadgeColor: Color(0xFFF2842B),
        );

      case DisabilityType.autismMild:
      case DisabilityType.autismSevere:
        return const AdaptiveVisuals(
          accentColor: Color(0xFF1AA9B2),
          surfaceColor: Color(0xFFF0F9FA),
          cardRadius: 16,
          buttonHeight: 56,
          iconSize: 26,
          titleFontSize: 18,
          bodyFontSize: 15,
          spacing: 16,
          animationSpeed: Duration(milliseconds: 500),
          profileLabel: 'وضع هادئ',
          profileEmoji: '🧩',
          profileBadgeColor: Color(0xFF1AA9B2),
        );

      case DisabilityType.downSyndrome:
        return const AdaptiveVisuals(
          accentColor: Color(0xFF57B25A),
          surfaceColor: Color(0xFFF1FAF1),
          cardRadius: 32,
          buttonHeight: 88,
          iconSize: 44,
          titleFontSize: 26,
          bodyFontSize: 22,
          spacing: 20,
          animationSpeed: Duration(milliseconds: 180),
          profileLabel: 'وضع مبسّط',
          profileEmoji: '💙',
          profileBadgeColor: Color(0xFF57B25A),
        );

      case DisabilityType.blind:
        return const AdaptiveVisuals(
          accentColor: Color(0xFFFFD400),
          surfaceColor: Color(0xFF000000),
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

      case DisabilityType.deaf:
        return const AdaptiveVisuals(
          accentColor: Color(0xFFF06C8B),
          surfaceColor: Color(0xFFFFF0F4),
          cardRadius: 22,
          buttonHeight: 70,
          iconSize: 36,
          titleFontSize: 22,
          bodyFontSize: 18,
          spacing: 18,
          animationSpeed: Duration(milliseconds: 200),
          profileLabel: 'وضع التنبيهات البصرية',
          profileEmoji: '👂',
          profileBadgeColor: Color(0xFFF06C8B),
        );

      case DisabilityType.stuttering:
        return const AdaptiveVisuals(
          accentColor: Color(0xFF8B6DD4),
          surfaceColor: Color(0xFFF5F1FF),
          cardRadius: 20,
          buttonHeight: 68,
          iconSize: 30,
          titleFontSize: 20,
          bodyFontSize: 17,
          spacing: 18,
          animationSpeed: Duration(milliseconds: 350),
          profileLabel: 'وضع النطق البطيء',
          profileEmoji: '🗣️',
          profileBadgeColor: Color(0xFF8B6DD4),
        );

      case DisabilityType.speechDisorders:
        return const AdaptiveVisuals(
          accentColor: Color(0xFF4A90A4),
          surfaceColor: Color(0xFFF0F6F8),
          cardRadius: 20,
          buttonHeight: 64,
          iconSize: 30,
          titleFontSize: 20,
          bodyFontSize: 17,
          spacing: 16,
          animationSpeed: Duration(milliseconds: 300),
          profileLabel: 'وضع النطق',
          profileEmoji: '💬',
          profileBadgeColor: Color(0xFF4A90A4),
        );

      case DisabilityType.mildIntellectual:
        return const AdaptiveVisuals(
          accentColor: Color(0xFFD98B2B),
          surfaceColor: Color(0xFFFDF6E3),
          cardRadius: 26,
          buttonHeight: 80,
          iconSize: 40,
          titleFontSize: 24,
          bodyFontSize: 20,
          spacing: 20,
          animationSpeed: Duration(milliseconds: 200),
          profileLabel: 'وضع خطوة بخطوة',
          profileEmoji: '🧠',
          profileBadgeColor: Color(0xFFD98B2B),
        );

      case DisabilityType.colorBlindness:
        return const AdaptiveVisuals(
          accentColor: Color(0xFF3A6EA5),
          surfaceColor: Color(0xFFF2F4F7),
          cardRadius: 18,
          buttonHeight: 60,
          iconSize: 30,
          titleFontSize: 19,
          bodyFontSize: 16,
          spacing: 14,
          animationSpeed: Duration(milliseconds: 220),
          profileLabel: 'وضع الرموز',
          profileEmoji: '🌈',
          profileBadgeColor: Color(0xFF3A6EA5),
        );

      case DisabilityType.epilepsy:
        return const AdaptiveVisuals(
          accentColor: Color(0xFF6B7C93),
          surfaceColor: Color(0xFFF7F8FA),
          cardRadius: 16,
          buttonHeight: 66,
          iconSize: 32,
          titleFontSize: 20,
          bodyFontSize: 17,
          spacing: 16,
          animationSpeed: Duration(milliseconds: 400),
          profileLabel: 'وضع آمن (بدون وميض)',
          profileEmoji: '⚕️',
          profileBadgeColor: Color(0xFF6B7C93),
        );

      case DisabilityType.other:
        return AdaptiveVisuals(
          accentColor: AppColors.teal,
          surfaceColor: AppColors.cream,
          cardRadius: 20,
          buttonHeight: 64,
          iconSize: 32,
          titleFontSize: 20,
          bodyFontSize: 17,
          spacing: 16,
          animationSpeed: const Duration(milliseconds: 250),
          profileLabel: p.customDisabilityName ?? 'وضع مخصّص',
          profileEmoji: '✏️',
          profileBadgeColor: AppColors.teal,
        );

      case DisabilityType.none:
        return const AdaptiveVisuals(
          accentColor: AppColors.tealDeep,
          surfaceColor: Colors.white,
          cardRadius: 20,
          buttonHeight: 56,
          iconSize: 28,
          titleFontSize: 18,
          bodyFontSize: 16,
          spacing: 12,
          animationSpeed: Duration(milliseconds: 250),
          profileLabel: 'الوضع العادي',
          profileEmoji: '⚪',
          profileBadgeColor: AppColors.tealDeep,
        );
    }
  }
}