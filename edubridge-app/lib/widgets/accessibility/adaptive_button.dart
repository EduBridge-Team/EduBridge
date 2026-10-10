// lib/widgets/adaptive/adaptive_button.dart
// زر يتكيّف تلقائياً: حجم، نطق، اهتزاز
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../utils/adaptive_helper.dart';

enum AdaptiveButtonStyle { filled, outlined, text }

class AdaptiveButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AdaptiveButtonStyle style;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool fullWidth;
  final bool enableReadOnTap;
  final double? fontSize;
  const AdaptiveButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.style = AdaptiveButtonStyle.filled,
    this.backgroundColor,
    this.foregroundColor,
    this.fullWidth = true,
    this.enableReadOnTap = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.profile,
      builder: (context, profile, _) {
        final height = AdaptiveHelper.buttonHeight;
        final fontSize = this.fontSize ?? AdaptiveHelper.bodyFontSize;
        final iconSize = AdaptiveHelper.iconSize * 0.8;

        // الألوان
        final effectiveBg = backgroundColor ??
            AdaptiveHelper.accentColor(context);
        final effectiveFg =
            foregroundColor ?? Colors.white;

        // عند اللمس
        void handleTap() {
          if (onPressed == null) return;

          // اهتزاز (للصمّ)
          AdaptiveHelper.hapticFeedback();

          // نطق النص قبل التنفيذ
          if (enableReadOnTap && profile.autoReadOnTap) {
            AdaptiveHelper.speak(label);
          }

          onPressed!();
        }

        Widget button;
        switch (style) {
          case AdaptiveButtonStyle.filled:
            button = ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: effectiveBg,
                foregroundColor: effectiveFg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                minimumSize: Size(48, height),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AdaptiveHelper.cardRadius - 4),
                ),
              ),
              onPressed: onPressed == null ? null : handleTap,
              child: _buildChild(fontSize, iconSize),
            );
            break;

          case AdaptiveButtonStyle.outlined:
            button = OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: effectiveBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                minimumSize: Size(48, height),
                side: BorderSide(
                  color: effectiveBg,
                  width: AdaptiveHelper.borderWidth,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AdaptiveHelper.cardRadius - 4),
                ),
              ),
              onPressed: onPressed == null ? null : handleTap,
              child: _buildChild(fontSize, iconSize),
            );
            break;

          case AdaptiveButtonStyle.text:
            button = TextButton(
              style: TextButton.styleFrom(
                foregroundColor: effectiveBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: Size(48, height * 0.8),
              ),
              onPressed: onPressed == null ? null : handleTap,
              child: _buildChild(fontSize, iconSize),
            );
            break;
        }

        if (!fullWidth) return button;
        return SizedBox(width: double.infinity, child: button);
      },
    );
  }

  Widget _buildChild(double fontSize, double iconSize) {
    final text = Text(
      label,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );

    if (icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize),
        const SizedBox(width: 10),
        Flexible(child: text),
      ],
    );
  }
}