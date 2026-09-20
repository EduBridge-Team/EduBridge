import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Noor is drawn with Flutter primitives so the assistant stays crisp,
/// offline-friendly, and consistent across light/dark themes.
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
    return Semantics(
      label: 'نور، المساعد الذكي',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final bob = math.sin(t * math.pi * 2) * 2.8;
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
    final scale = size.width / 120;
    canvas.save();
    canvas.scale(scale);

    final teal = AppColors.teal;
    final navy = AppColors.navy;
    final navyDeep = AppColors.navyDeep;
    const softBlue = Color(0xFFBFD2E5);
    final faceColor = dark ? const Color(0xFFF4FBFF) : Colors.white;

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: dark ? .26 : .13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(const Rect.fromLTWH(24, 91, 70, 9), shadow);

    final glow = Paint()
      ..color = teal.withValues(alpha: dark ? .22 : .16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawCircle(const Offset(59, 51), 43, glow);

    final tealPaint = Paint()..color = teal;
    final navyPaint = Paint()..color = navy;
    final softBluePaint = Paint()..color = softBlue;
    final whitePaint = Paint()..color = faceColor;

    final leftEar = Path()
      ..moveTo(31, 29)
      ..cubicTo(18, 27, 13, 18, 17, 10)
      ..cubicTo(22, 2, 34, 8, 43, 18)
      ..close();
    canvas.drawPath(leftEar, tealPaint);

    final leftEarInner = Path()
      ..moveTo(29, 24)
      ..cubicTo(23, 22, 20, 16, 22, 12)
      ..cubicTo(25, 8, 31, 12, 37, 18)
      ..close();
    canvas.drawPath(leftEarInner, navyPaint);

    final rightEar = Path()
      ..moveTo(82, 22)
      ..cubicTo(92, 12, 103, 9, 108, 17)
      ..cubicTo(112, 24, 107, 33, 95, 36)
      ..close();
    canvas.drawPath(rightEar, tealPaint);

    final rightEarInner = Path()
      ..moveTo(89, 23)
      ..cubicTo(95, 17, 101, 16, 103, 20)
      ..cubicTo(105, 24, 101, 29, 95, 31)
      ..close();
    canvas.drawPath(rightEarInner, navyPaint);

    final bodyPath = Path()
      ..moveTo(31, 19)
      ..cubicTo(41, 10, 53, 7, 66, 8)
      ..cubicTo(80, 8, 91, 15, 97, 26)
      ..cubicTo(104, 39, 104, 64, 94, 79)
      ..cubicTo(85, 93, 71, 99, 57, 99)
      ..cubicTo(42, 99, 27, 93, 20, 80)
      ..cubicTo(12, 66, 13, 42, 20, 30)
      ..cubicTo(23, 25, 26, 22, 31, 19)
      ..close();
    canvas.drawPath(bodyPath, tealPaint);

    canvas.save();
    canvas.translate(18, 69);
    canvas.rotate(-26 * math.pi / 180);
    canvas.drawOval(const Rect.fromLTWH(-10, -15, 20, 30), tealPaint);
    canvas.restore();

    final leftMitten = Path()
      ..moveTo(12, 66)
      ..cubicTo(7, 65, 3, 61, 4, 56)
      ..cubicTo(5, 52, 9, 53, 12, 56)
      ..cubicTo(10, 49, 12, 45, 16, 45)
      ..cubicTo(20, 45, 21, 51, 21, 55)
      ..cubicTo(23, 51, 27, 50, 30, 53)
      ..cubicTo(34, 58, 29, 64, 25, 68)
      ..cubicTo(21, 72, 17, 73, 12, 66)
      ..close();
    canvas.drawPath(leftMitten, whitePaint);
    canvas.drawPath(
      leftMitten,
      Paint()
        ..color = softBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.save();
    canvas.translate(101, 70);
    canvas.rotate(24 * math.pi / 180);
    canvas.drawOval(const Rect.fromLTWH(-10, -15, 20, 30), tealPaint);
    canvas.restore();

    final rightMitten = Path()
      ..moveTo(97, 67)
      ..cubicTo(93, 63, 90, 58, 93, 54)
      ..cubicTo(96, 50, 100, 52, 102, 56)
      ..cubicTo(102, 51, 104, 47, 108, 47)
      ..cubicTo(112, 47, 113, 52, 111, 57)
      ..cubicTo(114, 54, 118, 54, 120, 58)
      ..cubicTo(122, 63, 117, 68, 112, 70)
      ..cubicTo(106, 73, 101, 72, 97, 67)
      ..close();
    canvas.drawPath(rightMitten, whitePaint);
    canvas.drawPath(
      rightMitten,
      Paint()
        ..color = softBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawOval(const Rect.fromLTWH(25, 26, 66, 54), whitePaint);

    final blink = phase > .90 && phase < .95;
    final eyePaint = Paint()
      ..color = navyDeep
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    if (blink) {
      canvas.drawLine(const Offset(41, 51), const Offset(51, 51), eyePaint);
      canvas.drawLine(const Offset(65, 51), const Offset(75, 51), eyePaint);
    } else {
      canvas.drawCircle(const Offset(46, 50), 5, eyePaint);
      canvas.drawCircle(const Offset(70, 50), 5, eyePaint);
      canvas.drawCircle(const Offset(48, 47.5), 1.6, Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(72, 47.5), 1.6, Paint()..color = Colors.white);
    }

    canvas.drawCircle(const Offset(38.5, 61), 4.2, softBluePaint);
    canvas.drawCircle(const Offset(77.5, 61), 4.2, softBluePaint);

    final mouth = Path()
      ..moveTo(50, 63)
      ..cubicTo(53, 67, 56, 68, 59, 68)
      ..cubicTo(62, 68, 65, 67, 68, 63)
      ..cubicTo(67, 72, 64, 76, 59, 76)
      ..cubicTo(54, 76, 51, 72, 50, 63)
      ..close();
    canvas.drawPath(mouth, navyPaint);

    final mouthInner = Path()
      ..moveTo(54, 70)
      ..cubicTo(57, 68, 61, 68, 64, 70)
      ..cubicTo(63, 73, 61, 74, 59, 74)
      ..cubicTo(57, 74, 55, 73, 54, 70)
      ..close();
    canvas.drawPath(mouthInner, softBluePaint);

    final headset = Paint()
      ..color = navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bandPath = Path()
      ..moveTo(89, 39)
      ..cubicTo(101, 44, 105, 55, 102, 66)
      ..cubicTo(100, 71, 97, 75, 93, 78);
    canvas.drawPath(bandPath, headset);

    final thinHeadset = Paint()
      ..color = navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final sidePath = Path()
      ..moveTo(93, 62)
      ..cubicTo(97, 67, 94, 72, 89, 76);
    canvas.drawPath(sidePath, thinHeadset);

    canvas.drawCircle(const Offset(97, 57), 6.2, softBluePaint);
    canvas.drawCircle(
      const Offset(97, 57),
      6.2,
      Paint()
        ..color = navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final mic = Paint()
      ..color = navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final micPath = Path()
      ..moveTo(97, 68)
      ..cubicTo(93, 72, 88, 75, 84, 77);
    canvas.drawPath(micPath, mic);

    canvas.drawCircle(const Offset(80, 78), 11.5, navyPaint);

    final brain = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final brainPath = Path()
      ..moveTo(75, 80)
      ..cubicTo(71, 80, 70, 76, 72, 74)
      ..cubicTo(70, 71, 73, 68, 76, 69)
      ..cubicTo(78, 66, 82, 67, 83, 70)
      ..cubicTo(86, 69, 89, 71, 88, 74)
      ..cubicTo(90, 77, 87, 80, 84, 80);
    canvas.drawPath(brainPath, brain);
    canvas.drawLine(const Offset(77, 73), const Offset(77, 83), brain);
    canvas.drawLine(const Offset(83, 72), const Offset(83, 83), brain);
    canvas.drawLine(const Offset(77, 76), const Offset(83, 76), brain);
    canvas.drawLine(const Offset(77, 81), const Offset(82, 81), brain);
    final brainDot = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(75, 76), 1.1, brainDot);
    canvas.drawCircle(const Offset(84, 74), 1.1, brainDot);
    canvas.drawCircle(const Offset(84, 81), 1.1, brainDot);

    final attentionOpacity =
        .55 + ((math.sin(phase * math.pi * 2) + 1) / 2) * .45;
    final attention = Paint()
      ..color = softBlue.withValues(alpha: attentionOpacity);

    canvas.save();
    canvas.translate(104.5, 14);
    canvas.rotate(26 * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2.5, -6, 5, 12),
        const Radius.circular(2.5),
      ),
      attention,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(111.5, 23.5);
    canvas.rotate(55 * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2.5, -5.5, 5, 11),
        const Radius.circular(2.5),
      ),
      attention,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(111.5, 36.5);
    canvas.rotate(77 * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2.5, -5.5, 5, 11),
        const Radius.circular(2.5),
      ),
      attention,
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NoorPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.dark != dark;
}
