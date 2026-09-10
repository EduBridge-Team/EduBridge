import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A lightweight, asset-free animated companion. The whole character is drawn
/// with Flutter so it remains crisp, theme-friendly, and works offline.
class PetAvatar extends StatefulWidget {
  final double size;

  const PetAvatar({super.key, this.size = 76});

  @override
  State<PetAvatar> createState() => _PetAvatarState();
}

class _PetAvatarState extends State<PetAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'نور، المساعد الذكي',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final bob = math.sin(t * math.pi * 2) * 3;
          return Transform.translate(
            offset: Offset(0, bob),
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _NoorPainter(
                phase: t,
                dark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoorPainter extends CustomPainter {
  final double phase;
  final bool dark;

  const _NoorPainter({required this.phase, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 76;
    canvas.scale(scale);

    final shadow = Paint()
      ..color = Colors.black.withOpacity(dark ? .3 : .16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(const Rect.fromLTWH(14, 64, 48, 8), shadow);

    final glow = Paint()
      ..color = AppColors.yellow.withOpacity(.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(38, 35), 31, glow);

    final body = Paint()..color = AppColors.teal;
    final bodyPath = Path()
      ..moveTo(13, 30)
      ..quadraticBezierTo(8, 13, 25, 16)
      ..quadraticBezierTo(38, 4, 51, 16)
      ..quadraticBezierTo(68, 13, 63, 30)
      ..quadraticBezierTo(70, 54, 54, 64)
      ..quadraticBezierTo(38, 72, 22, 64)
      ..quadraticBezierTo(6, 54, 13, 30)
      ..close();
    canvas.drawPath(bodyPath, body);

    final ear = Paint()..color = AppColors.navy;
    canvas.drawPath(
      Path()
        ..moveTo(16, 28)
        ..lineTo(13, 10)
        ..lineTo(28, 20)
        ..close(),
      ear,
    );
    canvas.drawPath(
      Path()
        ..moveTo(60, 28)
        ..lineTo(63, 10)
        ..lineTo(48, 20)
        ..close(),
      ear,
    );

    final face = Paint()..color = dark ? const Color(0xFFE8F7F8) : Colors.white;
    canvas.drawOval(const Rect.fromLTWH(20, 24, 36, 31), face);

    final blink = phase > .9;
    final eye = Paint()
      ..color = AppColors.navyDeep
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    if (blink) {
      canvas.drawLine(const Offset(27, 37), const Offset(33, 37), eye);
      canvas.drawLine(const Offset(43, 37), const Offset(49, 37), eye);
    } else {
      canvas.drawCircle(const Offset(30, 36), 2.8, eye);
      canvas.drawCircle(const Offset(46, 36), 2.8, eye);
    }

    final beak = Paint()..color = AppColors.orange;
    canvas.drawPath(
      Path()
        ..moveTo(34, 42)
        ..lineTo(42, 42)
        ..lineTo(38, 47)
        ..close(),
      beak,
    );

    final badge = Paint()..color = AppColors.navy;
    canvas.drawCircle(const Offset(38, 58), 7, badge);
    final bridge = Paint()
      ..color = AppColors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(const Rect.fromLTWH(33, 54, 10, 7), math.pi, math.pi, false, bridge);
    canvas.drawLine(const Offset(32, 59), const Offset(44, 59), bridge);

    final sparkle = Paint()..color = AppColors.yellow;
    final sparkleY = 13 + math.sin(phase * math.pi * 2) * 2;
    canvas.drawCircle(Offset(68, sparkleY), 2.2, sparkle);
  }

  @override
  bool shouldRepaint(covariant _NoorPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.dark != dark;
}
