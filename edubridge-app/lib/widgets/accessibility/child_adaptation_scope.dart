import '../../l10n/l10n.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import 'brain_break_overlay.dart';

/// Delays child content until its saved profile is ready, and restores the
/// previous route on exit. The account profile remains unchanged.
class ChildAdaptationScope extends StatefulWidget {
  final int childId;
  final WidgetBuilder builder;
  const ChildAdaptationScope({super.key, required this.childId, required this.builder});

  @override
  State<ChildAdaptationScope> createState() => _ChildAdaptationScopeState();
}

class _ChildAdaptationScopeState extends State<ChildAdaptationScope> {
  final _service = AccessibilityService.instance;
  Object? _token;
  bool _ready = false;
  bool _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _enter();
  }

  Future<void> _enter() async {
    final generation = ++_generation;
    try {
      final token = await _service.enterChildScope(widget.childId);
      if (!mounted || generation != _generation) {
        await _service.leaveChildScope(token);
        return;
      }
      _token = token;
      setState(() { _ready = true; _failed = false; });
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant ChildAdaptationScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId == widget.childId) return;
    final token = _token;
    _token = null;
    _ready = false;
    _failed = false;
    if (token != null) unawaited(_service.leaveChildScope(token));
    _enter();
  }

  @override
  void dispose() {
    _generation++;
    final token = _token;
    if (token != null) unawaited(_service.leaveChildScope(token));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(body: Center(child: _failed
        ? TextButton(onPressed: _enter, child: Text(context.l10n.adaptationReload))
        : const CircularProgressIndicator()));
    }
    return BrainBreakScheduler(profileListenable: _service.profile,
      child: Builder(builder: widget.builder));
  }
}
