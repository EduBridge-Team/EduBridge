import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../utils/adaptive_helper.dart';
import 'adaptive_card.dart';
import 'adaptive_text.dart';

/// A non-scrolling grid for child catalogs. The parent owns scrolling so every
/// item remains reachable; variable-height tiles allow large text to wrap.
class SimpleIconsGrid extends StatelessWidget {
  const SimpleIconsGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final minimumWidth = math.max(160.0,
          MediaQuery.textScalerOf(context).scale(160));
      const spacing = 16.0;
      final columns = constraints.maxWidth >= minimumWidth * 2 + spacing ? 2 : 1;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    },
  );
}

/// One clear catalog target. Labels remain visible even in icon-only mode;
/// optional secondary actions retain existing lesson controls and permissions.
class SimpleIconTile extends StatelessWidget {
  const SimpleIconTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.status,
    this.actions,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final String? status;
  final Widget? actions;

  @override
  Widget build(BuildContext context) => AdaptiveCard(
    onTap: onTap == null ? null : () {
      if (AdaptiveHelper.shouldReadOnTap) AdaptiveHelper.speak(title);
      onTap!();
    },
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 88),
        child: Center(child: Icon(icon, size: math.max(48.0, AdaptiveHelper.iconSize),
            color: JisrColors.of(context).heading)),
      ),
      AdaptiveText(title, type: AdaptiveTextType.subtitle,
          textAlign: TextAlign.center, fontWeight: FontWeight.w800, enableTap: false),
      if (status != null) ...[
        const SizedBox(height: 8),
        AdaptiveText(status!, type: AdaptiveTextType.caption,
            textAlign: TextAlign.center, enableTap: false),
      ],
      if (actions != null) ...[
        const SizedBox(height: 12),
        actions!,
      ],
    ]),
  );
}
