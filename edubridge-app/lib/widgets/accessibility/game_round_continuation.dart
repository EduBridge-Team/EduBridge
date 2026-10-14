import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../utils/adaptive_feedback_policy.dart';

/// Keeps answered rounds available when the specialist disables timed interaction.
class GameRoundContinuation extends StatefulWidget {
  const GameRoundContinuation({super.key, required this.answered,
    required this.onContinue, this.delay = const Duration(milliseconds: 900)});

  final bool answered;
  final Future<void> Function() onContinue;
  final Duration delay;

  @override
  State<GameRoundContinuation> createState() => _GameRoundContinuationState();
}

class _GameRoundContinuationState extends State<GameRoundContinuation>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _busy = false;
  bool _continued = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  bool get _automatic => AdaptiveFeedbackPolicy(
    AccessibilityService.instance.profile.value).allowAutoDismiss;

  @override
  void initState() {
    super.initState();
    _lifecycle = WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    AccessibilityService.instance.profile.addListener(_preferencesChanged);
    _schedule();
  }

  @override
  void didUpdateWidget(covariant GameRoundContinuation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answered && !widget.answered) _continued = false;
    if (oldWidget.answered != widget.answered || oldWidget.delay != widget.delay) _schedule();
  }

  void _preferencesChanged() {
    _schedule();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!widget.answered || _busy || _continued || !_automatic ||
        _lifecycle != AppLifecycleState.resumed) return;
    _timer = Timer(widget.delay, () {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent == false) {
        _schedule();
        return;
      }
      unawaited(_continue());
    });
  }

  Future<void> _continue() async {
    if (!mounted || !widget.answered || _busy || _continued) return;
    _timer?.cancel();
    setState(() { _busy = true; _continued = true; });
    try {
      await widget.onContinue();
    } catch (_) {
      if (!mounted) return;
      _continued = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر متابعة اللعبة، حاول مرة أخرى')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AccessibilityService.instance.profile.removeListener(_preferencesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => !widget.answered
    ? const SizedBox.shrink()
    : Padding(padding: const EdgeInsets.only(top: 12), child: FilledButton(
        onPressed: _busy || _continued ? null : _continue,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(_busy ? 'جارٍ المتابعة' : 'متابعة')),
      ));
}
