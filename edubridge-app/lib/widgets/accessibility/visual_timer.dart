// مؤقّت بصري دائري — مع أزرار تحكم + اهتزاز للأصمّ
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/accessibility_service.dart';
import '../../theme.dart';

class VisualTimer extends StatefulWidget {
  final Duration total;
  final VoidCallback? onFinished;
  final double size;
  final Color? color;
  final String? label;
  final bool autoStart;
  final bool showControls;

  const VisualTimer({
    super.key,
    required this.total,
    this.onFinished,
    this.size = 160,
    this.color,
    this.label,
    this.autoStart = true,
    this.showControls = true,
  });

  @override
  State<VisualTimer> createState() => _VisualTimerState();
}

class _VisualTimerState extends State<VisualTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _ticker;
  bool _isPaused = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.total)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _finish();
        }
      });
    if (widget.autoStart) {
      _start();
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isPaused && !_isFinished) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _start() {
    if (_isFinished) return;
    _ctrl.forward();
    setState(() => _isPaused = false);
  }

  void _pause() {
    if (_isFinished) return;
    _ctrl.stop();
    setState(() => _isPaused = true);
  }

  void _resume() {
    if (_isFinished) return;
    _ctrl.forward();
    setState(() => _isPaused = false);
  }

  void _reset() {
    _ctrl.reset();
    _isFinished = false;
    setState(() {});
    if (widget.autoStart) _start();
  }

  void _restart() {
    _ctrl.reset();
    _isFinished = false;
    setState(() {});
    _start();
  }

  void _finish() {
    _isFinished = true;
    if (mounted) setState(() {});

    // ✅ للأصمّ: اهتزاز قوي لجذب الانتباه
    final profile = AccessibilityService.instance.profile.value;
    if (profile.type == DisabilityType.deaf) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.heavyImpact();
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        HapticFeedback.heavyImpact();
      });
    }

    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final remaining = widget.total * (1 - _ctrl.value);
    final secs = remaining.inSeconds;
    final mm = (secs ~/ 60).toString().padLeft(2, '0');
    final ss = (secs % 60).toString().padLeft(2, '0');
    final progress = 1 - _ctrl.value;

    Color progressColor;
    if (_isFinished) {
      progressColor = AppColors.green;
    } else if (progress < 0.2) {
      progressColor = Colors.red;
    } else if (progress < 0.5) {
      progressColor = AppColors.orange;
    } else {
      progressColor = widget.color ?? AppColors.teal;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      value: _isFinished ? 1 : progress,
                      strokeWidth: 14,
                      strokeCap: StrokeCap.round,
                      color: progressColor,
                      backgroundColor: c.line,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isFinished)
                        const Text('🎉', style: TextStyle(fontSize: 44))
                      else
                        Text(
                          '$mm:$ss',
                          style: TextStyle(
                            fontSize: widget.size * 0.22,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          ),
                        ),
                      if (_isFinished) ...[
                        const SizedBox(height: 4),
                        Text(
                          'انتهى!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: c.success,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.muted,
            ),
          ),
        ],
        if (widget.showControls) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isFinished)
                _ControlButton(
                  icon: Icons.replay,
                  label: 'من جديد',
                  color: AppColors.green,
                  onTap: _restart,
                )
              else ...[
                _ControlButton(
                  icon: _isPaused ? Icons.play_arrow : Icons.pause,
                  label: _isPaused ? 'متابعة' : 'إيقاف',
                  color: AppColors.orange,
                  onTap: _isPaused ? _resume : _pause,
                ),
                const SizedBox(width: 12),
                _ControlButton(
                  icon: Icons.refresh,
                  label: 'إعادة',
                  color: AppColors.teal,
                  onTap: _reset,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 1.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}