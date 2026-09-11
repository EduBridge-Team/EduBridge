// غلاف موحّد يستمع لبروفايل الإعاقة ويطبّق التعديلات تلقائياً
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/accessibility_service.dart';
import 'brain_break_overlay.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget child;
  const AdaptiveScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.profile,
      builder: (context, profile, _) {
        if (profile.sensoryCalmMode) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }

        Widget wrapped = BrainBreakScheduler(child: child);

        if (profile.autoReadOnTap || profile.type == DisabilityType.blind) {
          wrapped = Semantics(
            container: true,
            explicitChildNodes: true,
            child: wrapped,
          );
        }

        return wrapped;
      },
    );
  }
}