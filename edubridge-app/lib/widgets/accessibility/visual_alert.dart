// تنبيه بصري بديل لكل صوت/إشعار — يظهر كشريط ملوّن مع وميض خفيف
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../theme.dart';

class VisualAlert extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color? color;
  final Duration duration;
  final VoidCallback? onDismiss;

  const VisualAlert({
    super.key,
    required this.message,
    this.icon,
    this.color,
    this.duration = const Duration(seconds: 4),
    this.onDismiss,
  });

  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: 24,
        left: 16,
        right: 16,
        child: VisualAlert(
          message: message,
          icon: icon,
          color: color,
          duration: duration,
          onDismiss: () => entry.remove(),
        ),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<VisualAlert> createState() => _VisualAlertState();
}

class _VisualAlertState extends State<VisualAlert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _visible = true;
  Timer? _timeout;
  bool _dismissed = false;
  bool get _untimed {
    final p = AccessibilityService.instance.profile.value;
    return p.noTimedInteractions || p.noTimers || p.unlimitedTime;
  }
  void _dismiss() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    setState(() => _visible = false);
    widget.onDismiss?.call();
  }
  void _syncPreferences() {
    if (!mounted) return;
    final p = AccessibilityService.instance.profile.value;
    final still = p.reducedAnimations || p.noFlashing || !p.flashAlerts ||
        MediaQuery.disableAnimationsOf(context);
    if (still) {
      _ctrl.stop();
      _ctrl.value = 0;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    }
    _timeout?.cancel();
    if (!_untimed) _timeout = Timer(widget.duration, _dismiss);
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPreferences();
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    AccessibilityService.instance.profile.addListener(_syncPreferences);
  }

  @override
  void dispose() {
    AccessibilityService.instance.profile.removeListener(_syncPreferences);
    _timeout?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final color = widget.color ?? AppColors.orange;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final glow = 0.5 + _ctrl.value * 0.5;
        return Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: glow),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(widget.icon ?? Icons.notifications_active,
                color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(tooltip: 'إغلاق التنبيه', onPressed: _dismiss,
              icon: const Icon(Icons.close, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

void notifyUser(BuildContext context, String message,
    {IconData? icon, Color? color}) {
  final p = AccessibilityService.instance.profile.value;
  if (p.visualAlertsEnabled) {
    VisualAlert.show(context, message, icon: icon, color: color);
  } else {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}