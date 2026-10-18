import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';

/// Optional reduced-saturation presentation for child navigation surfaces.
/// Keep this outside media and game routes: their original colours can be part
/// of the learning task. This is not a colour-vision correction algorithm.
class ChildColorFilter extends StatelessWidget {
  const ChildColorFilter({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  // 60% saturation, retaining neutral black/white and the alpha channel.
  static const _softColors = ColorFilter.matrix(<double>[
    .68504, .28608, .02888, 0, 0,
    .08504, .88608, .02888, 0, 0,
    .08504, .28608, .62888, 0, 0,
    0, 0, 0, 1, 0,
  ]);
  static const _originalColors = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AccessibilityProfile>(
    valueListenable: AccessibilityService.instance.profile,
    child: child,
    builder: (context, profile, child) => ColorFiltered(
      // Keep the same tree when toggled, preserving scroll, focus and inputs.
      colorFilter: enabled && profile.colorFiltersEnabled ? _softColors : _originalColors,
      child: child!,
    ),
  );
}
