// غلاف موحّد يستمع لبروفايل الإعاقة ويطبّق التعديلات تلقائياً
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/accessibility_service.dart';
import 'brain_break_overlay.dart';

class AdaptiveScaffold extends StatefulWidget {
  final Widget child;
  const AdaptiveScaffold({super.key, required this.child});

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  // ✅ إصلاح: نتتبّع القيمة السابقة لتجنّب استدعاء SystemChrome عند كل build
  bool _lastCalmMode = false;

  @override
  void initState() {
    super.initState();
    AccessibilityService.instance.applicationProfile.addListener(_onProfileChanged);
    _lastCalmMode = AccessibilityService.instance.applicationProfile.value.sensoryCalmMode;
    _applySystemUi();
  }

  @override
  void dispose() {
    AccessibilityService.instance.applicationProfile.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    _applySystemUi();
    if (mounted) setState(() {});
  }

  void _applySystemUi() {
    final p = AccessibilityService.instance.applicationProfile.value;
    if (p.sensoryCalmMode == _lastCalmMode) return;

    _lastCalmMode = p.sensoryCalmMode;

    // ✅ Side-effect خارج build — يُستدعى فقط عند تغيّر حقيقي
    if (p.sensoryCalmMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = AccessibilityService.instance.applicationProfile.value;

    Widget wrapped = BrainBreakScheduler(child: widget.child);

    if (profile.autoReadOnTap || profile.type == DisabilityType.blind) {
      wrapped = Semantics(
        container: true,
        explicitChildNodes: true,
        child: wrapped,
      );
    }

    return wrapped;
  }
}