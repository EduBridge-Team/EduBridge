import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Noor is drawn with Flutter primitives so the assistant stays crisp,
/// offline-friendly, and visually identical to the website mascot.
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
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      label: 'نور، المساعد الذكي',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final phase = reduceMotion ? 0.0 : _controller.value;
          final bob =
              reduceMotion ? 0.0 : math.sin(phase * math.pi * 2) * 2.8;
          return Transform.translate(
            offset: Offset(0, bob),
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _NoorPainter(phase: phase),
            ),
          );
        },
      ),
    );
  }
}

class _NoorPainter extends CustomPainter {
  final double phase;

  const _NoorPainter({required this.phase});

  static const _softBlue = Color(0xFFC5D9E9);
  static const _deepBlue = Color(0xFF0B3F96);
  static const _midBlue = Color(0xFF176DCC);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 140;
    canvas
      ..save()
      ..scale(scale)
      ..translate(0, 12);

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF58DDD2), Color(0xFF20B7C9)],
      ).createShader(const Rect.fromLTWH(20, 8, 104, 104));
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_midBlue, _deepBlue],
      ).createShader(const Rect.fromLTWH(28, 12, 104, 96));
    final facePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.2, -.3),
        radius: .95,
        colors: [Colors.white, Color(0xFFF2F9FD)],
      ).createShader(const Rect.fromLTWH(32, 30, 76, 62));
    final whitePaint = Paint()..color = Colors.white;
    final softBluePaint = Paint()..color = _softBlue;

    canvas.drawOval(
      const Rect.fromLTWH(31, 103, 78, 10),
      Paint()
        ..color = Colors.black.withValues(alpha: .14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      const Offset(70, 58),
      48,
      Paint()
        ..color = const Color(0xFF32C9C4).withValues(alpha: .16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    final leftEar = Path()
      ..moveTo(43, 35)
      ..cubicTo(28, 34, 20, 24, 23, 13)
      ..cubicTo(26, 3, 42, 8, 53, 22)
      ..close();
    canvas.drawPath(leftEar, bodyPaint);
    final leftEarInner = Path()
      ..moveTo(39, 29)
      ..cubicTo(32, 27, 29, 21, 31, 16)
      ..cubicTo(34, 12, 42, 17, 47, 23)
      ..close();
    canvas.drawPath(leftEarInner, bluePaint);

    final rightEar = Path()
      ..moveTo(92, 25)
      ..cubicTo(104, 12, 119, 11, 123, 21)
      ..cubicTo(127, 31, 119, 40, 106, 42)
      ..close();
    canvas.drawPath(rightEar, bodyPaint);
    final rightEarInner = Path()
      ..moveTo(101, 26)
      ..cubicTo(108, 19, 116, 18, 118, 23)
      ..cubicTo(120, 28, 115, 34, 108, 36)
      ..close();
    canvas.drawPath(rightEarInner, bluePaint);

    final rearHeadsetPaint = Paint()
      ..color = _midBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final rearHeadset = Path()
      ..moveTo(104, 38)
      ..cubicTo(115, 41, 121, 49, 120, 59);
    canvas.drawPath(rearHeadset, rearHeadsetPaint);

    final body = Path()
      ..moveTo(40, 24)
      ..cubicTo(50, 14, 61, 10, 74, 10)
      ..cubicTo(91, 10, 105, 18, 113, 32)
      ..cubicTo(121, 47, 120, 73, 111, 90)
      ..cubicTo(103, 104, 88, 111, 70, 111)
      ..cubicTo(51, 111, 35, 104, 27, 89)
      ..cubicTo(18, 73, 19, 47, 27, 34)
      ..cubicTo(30, 29, 35, 26, 40, 24)
      ..close();
    canvas.drawPath(body, bodyPaint);
    final bodyHighlight = Path()
      ..moveTo(35, 35)
      ..cubicTo(45, 21, 61, 15, 77, 16)
      ..cubicTo(61, 19, 48, 26, 40, 38)
      ..cubicTo(31, 52, 30, 71, 35, 86)
      ..cubicTo(25, 70, 26, 49, 35, 35)
      ..close();
    canvas.drawPath(
      bodyHighlight,
      Paint()..color = Colors.white.withValues(alpha: .12),
    );

    canvas.save();
    canvas.translate(25, 80);
    canvas.rotate(-28 * math.pi / 180);
    canvas.drawOval(const Rect.fromLTWH(-11, -17, 22, 34), bodyPaint);
    canvas.restore();
    canvas.save();
    canvas.translate(116, 80);
    canvas.rotate(28 * math.pi / 180);
    canvas.drawOval(const Rect.fromLTWH(-11, -17, 22, 34), bodyPaint);
    canvas.restore();

    final armShade = Paint()
      ..color = _midBlue.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(27, 66)
        ..cubicTo(23, 75, 25, 86, 32, 93),
      armShade,
    );
    canvas.drawPath(
      Path()
        ..moveTo(113, 66)
        ..cubicTo(117, 75, 115, 86, 108, 93),
      armShade,
    );

    final leftMitten = Path()
      ..moveTo(17, 79)
      ..cubicTo(10, 79, 4, 75, 4, 69)
      ..cubicTo(4, 64, 9, 64, 13, 68)
      ..cubicTo(10, 60, 13, 55, 18, 56)
      ..cubicTo(22, 57, 23, 63, 23, 67)
      ..cubicTo(27, 62, 32, 63, 34, 67)
      ..cubicTo(37, 73, 31, 79, 26, 82)
      ..cubicTo(23, 84, 20, 83, 17, 79)
      ..close();
    final rightMitten = Path()
      ..moveTo(113, 79)
      ..cubicTo(108, 74, 106, 68, 110, 64)
      ..cubicTo(114, 61, 118, 64, 120, 68)
      ..cubicTo(120, 62, 123, 58, 127, 59)
      ..cubicTo(132, 60, 132, 66, 129, 71)
      ..cubicTo(134, 67, 139, 69, 140, 74)
      ..cubicTo(141, 80, 134, 84, 128, 85)
      ..cubicTo(122, 87, 117, 84, 113, 79)
      ..close();
    final mittenOutline = Paint()
      ..color = _softBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(leftMitten, whitePaint)
      ..drawPath(leftMitten, mittenOutline)
      ..drawPath(rightMitten, whitePaint)
      ..drawPath(rightMitten, mittenOutline);

    canvas.drawOval(
      const Rect.fromLTWH(31, 29, 78, 64),
      Paint()..color = _softBlue.withValues(alpha: .42),
    );
    canvas.drawOval(const Rect.fromLTWH(34, 32, 72, 58), facePaint);

    final blink = phase > .90 && phase < .95;
    final eyePaint = Paint()
      ..shader = bluePaint.shader
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    if (blink) {
      canvas.drawLine(const Offset(50, 58), const Offset(62, 58), eyePaint);
      canvas.drawLine(const Offset(78, 58), const Offset(90, 58), eyePaint);
    } else {
      canvas.drawOval(const Rect.fromLTWH(50.2, 50, 11.6, 14), eyePaint);
      canvas.drawOval(const Rect.fromLTWH(78.2, 50, 11.6, 14), eyePaint);
      canvas.drawCircle(const Offset(58, 53.8), 1.8, whitePaint);
      canvas.drawCircle(const Offset(86, 53.8), 1.8, whitePaint);
    }
    canvas.drawCircle(const Offset(46, 70), 4.8, softBluePaint);
    canvas.drawCircle(const Offset(94, 70), 4.8, softBluePaint);

    final mouth = Path()
      ..moveTo(61, 70)
      ..cubicTo(67, 72, 74, 72, 80, 70)
      ..cubicTo(79, 80, 76, 85, 70, 85)
      ..cubicTo(64, 85, 61, 80, 61, 70)
      ..close();
    canvas.drawPath(mouth, bluePaint);
    final mouthInner = Path()
      ..moveTo(65, 79)
      ..cubicTo(68, 76, 73, 76, 76, 79)
      ..cubicTo(75, 82, 73, 83, 70, 83)
      ..cubicTo(68, 83, 66, 82, 65, 79)
      ..close();
    canvas.drawPath(mouthInner, softBluePaint);

    final mic = Path()
      ..moveTo(115, 70)
      ..cubicTo(114, 79, 107, 86, 99, 89);
    canvas.drawPath(
      mic,
      Paint()
        ..color = _midBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      const Rect.fromLTWH(106.5, 54.5, 15, 19),
      Paint()..color = _midBlue,
    );
    canvas.drawOval(const Rect.fromLTWH(111.4, 57.2, 9.2, 13.6), softBluePaint);

    canvas.drawCircle(const Offset(91, 88), 13, bluePaint);
    final brain = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final brainOutline = Path()
      ..moveTo(85, 91)
      ..cubicTo(80, 91, 79, 86, 82, 83)
      ..cubicTo(80, 79, 84, 76, 88, 78)
      ..cubicTo(90, 74, 95, 75, 96, 79)
      ..cubicTo(100, 78, 103, 82, 101, 85)
      ..cubicTo(104, 89, 100, 93, 96, 92);
    canvas.drawPath(brainOutline, brain);
    canvas.drawLine(const Offset(88, 82), const Offset(88, 96), brain);
    canvas.drawLine(const Offset(95, 80), const Offset(95, 96), brain);
    canvas.drawLine(const Offset(88, 86), const Offset(95, 86), brain);
    canvas.drawLine(const Offset(88, 92), const Offset(94, 92), brain);
    final brainDot = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(85, 86), 1.2, brainDot);
    canvas.drawCircle(const Offset(97, 83), 1.2, brainDot);
    canvas.drawCircle(const Offset(97, 91), 1.2, brainDot);

    final pulse = .55 + ((math.sin(phase * math.pi * 2) + 1) / 2) * .45;
    final attentionPaint =
        Paint()..color = _softBlue.withValues(alpha: pulse);
    _drawAttention(
      canvas,
      const Offset(121.75, 17),
      5.5,
      14,
      27,
      attentionPaint,
    );
    _drawAttention(
      canvas,
      const Offset(129.75, 28.5),
      5.5,
      13,
      56,
      attentionPaint,
    );
    _drawAttention(
      canvas,
      const Offset(130.75, 43.5),
      5.5,
      13,
      77,
      attentionPaint,
    );

    canvas.restore();
  }

  void _drawAttention(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: width, height: height),
        Radius.circular(width / 2),
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NoorPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
