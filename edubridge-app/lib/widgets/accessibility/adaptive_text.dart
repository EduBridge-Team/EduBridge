// lib/widgets/adaptive/adaptive_text.dart
// نص يتكيّف تلقائياً مع البروفايل — مع دعم fontWeight + تبسيط اللغة
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../services/simple_language_service.dart';
import '../../utils/adaptive_helper.dart';
import 'adaptive_wrapper.dart';

enum AdaptiveTextType { body, title, subtitle, caption, label }

class AdaptiveText extends StatelessWidget {
  final String text;
  final AdaptiveTextType type;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableTap;
  final Color? color;
  final FontWeight? fontWeight;      // ✅ أُعيد
  final VoidCallback? onTap;

  const AdaptiveText(
    this.text, {
    super.key,
    this.type = AdaptiveTextType.body,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableTap = true,
    this.color,
    this.fontWeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.profile,
      builder: (context, profile, _) {
        // ═══════════════════════════════════════════════
        //  1. وضع الأيقونات فقط → إخفاء النص (ما عدا العنوان)
        // ═══════════════════════════════════════════════
        if (IconOnlyScope.of(context) &&
            type != AdaptiveTextType.title) {
          return const SizedBox.shrink();
        }

        // ═══════════════════════════════════════════════
        //  2. تبسيط اللغة
        // ═══════════════════════════════════════════════
        String finalText = text;
        if (profile.verySimpleLanguage) {
          finalText = SimpleLanguageService.instance.simplify(finalText);
        }
        if (profile.shortSentences &&
            type == AdaptiveTextType.body) {
          finalText =
              SimpleLanguageService.instance.shorten(finalText, maxWords: 6);
        }

        // ═══════════════════════════════════════════════
        //  3. الأنماط
        // ═══════════════════════════════════════════════
        final fontSize = _fontSizeFor(type);
        final effectiveColor = color ?? AdaptiveHelper.textColor(context);
        final effectiveWeight = fontWeight ?? _weightFor(type);

        final textWidget = Text(
          finalText,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow ?? TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: effectiveWeight,
            color: effectiveColor,
            height: 1.5,
          ),
        );

        // ═══════════════════════════════════════════════
        //  4. قارئ الشاشة (Semantics)
        // ═══════════════════════════════════════════════
        final semanticWidget = profile.screenReaderOptimized
            ? Semantics(
                label: finalText,
                child: textWidget,
              )
            : textWidget;

        // ═══════════════════════════════════════════════
        //  5. نطق عند اللمس
        // ═══════════════════════════════════════════════
        if ((profile.autoReadOnTap && enableTap) || onTap != null) {
          return GestureDetector(
            onTap: () {
              if (profile.autoReadOnTap && enableTap) {
                AdaptiveHelper.speak(finalText);
              }
              onTap?.call();
            },
            child: semanticWidget,
          );
        }

        return semanticWidget;
      },
    );
  }

  double _fontSizeFor(AdaptiveTextType t) {
    switch (t) {
      case AdaptiveTextType.title:
        return AdaptiveHelper.titleFontSize;
      case AdaptiveTextType.subtitle:
        return AdaptiveHelper.subtitleFontSize;
      case AdaptiveTextType.body:
        return AdaptiveHelper.bodyFontSize;
      case AdaptiveTextType.caption:
        return AdaptiveHelper.bodyFontSize - 2;
      case AdaptiveTextType.label:
        return AdaptiveHelper.bodyFontSize - 4;
    }
  }

  FontWeight _weightFor(AdaptiveTextType t) {
    switch (t) {
      case AdaptiveTextType.title:
        return FontWeight.bold;
      case AdaptiveTextType.subtitle:
        return FontWeight.w600;
      case AdaptiveTextType.label:
        return FontWeight.w500;
      default:
        return FontWeight.normal;
    }
  }
}