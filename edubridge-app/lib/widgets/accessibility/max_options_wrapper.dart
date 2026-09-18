// lib/widgets/adaptive/max_options_wrapper.dart
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';

class MaxOptionsWrapper extends StatelessWidget {
  final List<Widget> options;
  final int defaultMax;

  const MaxOptionsWrapper({
    super.key,
    required this.options,
    this.defaultMax = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.profile,
      builder: (context, profile, _) {
        final max = profile.maxOptionsCount3 ? 3 : defaultMax;
        final visible = options.take(max).toList();

        return Column(children: visible);
      },
    );
  }
}