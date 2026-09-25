// Animated onboarding background and page model.
part of 'welcome_screen.dart';

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _BackgroundPainter(progress: controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double progress;

  _BackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * math.pi;

    // ─── التدرّج الأساسي ───
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF0F7FF),
          Color(0xFFF8FBFF),
          Color(0xFFF0F7FF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bgPaint,
    );

    // ─── دائرة أزرق ملكي ───
    final blueBlob = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.brandBlue.withValues(alpha: 0.20),
          AppColors.brandBlue.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.05 + math.sin(t) * 12,
          size.height * 0.08 + math.cos(t) * 12,
        ),
        radius: size.width * 0.55,
      ));
    canvas.drawCircle(
      Offset(
        size.width * 0.05 + math.sin(t) * 12,
        size.height * 0.08 + math.cos(t) * 12,
      ),
      size.width * 0.55,
      blueBlob,
    );

    // ─── دائرة تركوازية ───
    final tealBlob = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.brandTeal.withValues(alpha: 0.22),
          AppColors.brandTeal.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.95 + math.cos(t) * 15,
          size.height * 0.75 + math.sin(t) * 15,
        ),
        radius: size.width * 0.45,
      ));
    canvas.drawCircle(
      Offset(
        size.width * 0.95 + math.cos(t) * 15,
        size.height * 0.75 + math.sin(t) * 15,
      ),
      size.width * 0.45,
      tealBlob,
    );

    // ─── دائرة خضراء (الهوية) ───
    final greenBlob = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.brandGreen.withValues(alpha: 0.18),
          AppColors.brandGreen.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.5 + math.sin(t * 0.8) * 25,
          size.height * 0.4 + math.cos(t * 0.9) * 20,
        ),
        radius: size.width * 0.30,
      ));
    canvas.drawCircle(
      Offset(
        size.width * 0.5 + math.sin(t * 0.8) * 25,
        size.height * 0.4 + math.cos(t * 0.9) * 20,
      ),
      size.width * 0.30,
      greenBlob,
    );

    // ─── جزيئات ───
    _drawParticle(
      canvas,
      Offset(
        size.width * 0.15 + math.sin(t * 1.3) * 20,
        size.height * 0.30 + math.cos(t * 1.1) * 20,
      ),
      6,
      AppColors.brandTeal.withValues(alpha: 0.35),
    );
    _drawParticle(
      canvas,
      Offset(
        size.width * 0.85 + math.cos(t * 0.9) * 25,
        size.height * 0.20 + math.sin(t * 1.2) * 20,
      ),
      8,
      AppColors.brandBlue.withValues(alpha: 0.28),
    );
    _drawParticle(
      canvas,
      Offset(
        size.width * 0.75 + math.sin(t * 1.5) * 18,
        size.height * 0.55 + math.cos(t * 1.4) * 18,
      ),
      5,
      AppColors.brandGreen.withValues(alpha: 0.55),
    );
    _drawParticle(
      canvas,
      Offset(
        size.width * 0.20 + math.cos(t * 1.7) * 22,
        size.height * 0.65 + math.sin(t * 1.6) * 22,
      ),
      7,
      AppColors.brandBlue.withValues(alpha: 0.22),
    );

    // ─── حلقة رقيقة ───
    final ringPaint = Paint()
      ..color = AppColors.brandBlue.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.65,
      ringPaint,
    );
  }

  void _drawParticle(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _OnboardingPage {
  final String image;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
