// lib/widgets/adaptive/adaptive_card.dart
// كارت يتكيّف: حواف، حدود، تباين
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../utils/adaptive_helper.dart';

class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.profile,
      builder: (context, profile, _) {
        final radius = AdaptiveHelper.cardRadius;
        final bgColor = backgroundColor ?? AdaptiveHelper.cardColor(context);
        final effectiveBorder = borderColor ??
            (profile.highContrast
                ? const Color(0xFFFFD400)
                : Theme.of(context).dividerColor);

        final container = Container(
          padding: padding ?? EdgeInsets.all(AdaptiveHelper.spacing),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: effectiveBorder,
              width: AdaptiveHelper.borderWidth,
            ),
          ),
          child: child,
        );

        if (onTap == null) return container;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: container,
          ),
        );
      },
    );
  }
}