// lib/widgets/adaptive/adaptive_icon.dart
// أيقونة تتكيّف مع الحجم + نطق
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../utils/adaptive_helper.dart';

class AdaptiveIcon extends StatelessWidget {
  final IconData icon;
  final String? semanticLabel;
  final Color? color;
  final double? size;
  final bool enableReadOnTap;

  const AdaptiveIcon(
    this.icon, {
    super.key,
    this.semanticLabel,
    this.color,
    this.size,
    this.enableReadOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.profile,
      builder: (context, profile, _) {
        final effectiveSize = size ?? AdaptiveHelper.iconSize;
        final effectiveColor = color ?? AdaptiveHelper.textColor(context);
        final shouldRead = enableReadOnTap &&
            profile.autoReadOnTap &&
            semanticLabel != null;

        final iconWidget = Icon(
          icon,
          size: effectiveSize,
          color: effectiveColor,
        );

        if (!shouldRead) return iconWidget;

        return GestureDetector(
          onTap: () {
            if (semanticLabel != null) {
              AdaptiveHelper.speak(semanticLabel!);
            }
          },
          child: Semantics(
            label: semanticLabel,
            button: true,
            child: iconWidget,
          ),
        );
      },
    );
  }
}