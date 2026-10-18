import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import 'large_mouse_cursor.dart';

/// A single app-level cursor follows the active child lease, including child
/// dialogs and game routes. Account screens keep their ordinary system cursor.
class ChildMouseCursor extends StatelessWidget {
  const ChildMouseCursor({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final service = AccessibilityService.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([service.profile, service.activeChildId]),
      child: child,
      builder: (context, child) => LargeMouseCursor(
        enabled: service.activeChildId.value != null &&
            service.profile.value.largeMouseCursor,
        child: child!,
      ),
    );
  }
}
