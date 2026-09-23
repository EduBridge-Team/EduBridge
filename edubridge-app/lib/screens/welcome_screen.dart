// الشاشة الترحيبية — 3 واجهات فاخرة مع خلفية متحركة
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _currentPage = 0;

  late final AnimationController _bgController;
  late final AnimationController _floatController;
  late final AnimationController _fadeController;

  static const _pages = [
    _OnboardingPage(
      image: 'assets/3.png',
      title: 'معاً ندعم تقدُّمه',
      subtitle:
          'متابعة ذكية تجمع الأسرة والمعلم والمختص لدعم طفلك والاحتفاء بكل إنجاز يحققه.',
    ),
    _OnboardingPage(
      image: 'assets/2.png',
      title: 'التعلُّم حق للجميع',
      subtitle:
          'تجربة تعليمية شاملة وتفاعلية تمنح كل طفل فرصة ليتعلّم ويشارك بطريقته الخاصة.',
    ),
    _OnboardingPage(
      image: 'assets/1.png',
      title: 'خطوة بخطوة نحو إمكاناته',
      subtitle:
          'نرافق طفلك في رحلة تعليمية ممتعة، مصممة لتناسب قدراته وتساعده على الوصول إلى أهدافه.',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void initState() {
    super.initState();

    // دوران بطيء جداً للخلفية
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // طفو الصورة
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // ظهور/اختفاء زر "ابدأ"
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgController.dispose();
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _currentPage = i);

    // إظهار/إخفاء زر "ابدأ" حسب الصفحة
    if (i == _pages.length - 1) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: Stack(
        children: [
          // ═══════════════════════════════════════════════
          //  خلفية متحركة فاخرة (دوائر + أشكال طافية)
          // ═══════════════════════════════════════════════
          _AnimatedBackground(controller: _bgController),

          // ═══════════════════════════════════════════════
          //  المحتوى
          // ═══════════════════════════════════════════════
          SafeArea(
            child: Column(
              children: [
                // ─── زر Skip أعلى اليمين ───
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                    child: TextButton(
                      onPressed: _goToLogin,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(
                            color: AppColors.navy.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── الصفحات ───
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, i) => _buildPage(_pages[i], i),
                  ),
                ),

                // ─── النقاط الدلالية ───
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.navy
                              : AppColors.navy.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: AppColors.navy
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),

                // ─── زر "ابدأ" يظهر فقط في الصفحة الأخيرة ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _fadeController,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLastPage ? _goToLogin : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor: Colors.transparent,
                            elevation: 8,
                            shadowColor: AppColors.navy.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ابدأ',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, int index) {
    final isCurrent = index == _currentPage;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
          // ═══════════════════════════════════════════════
          //  صورة الدرس — مع حركة طفو خفيفة + هالة ضوئية
          // ═══════════════════════════════════════════════
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              // طفو عمودي ± 8 بكسل
              final dy = (_floatController.value - 0.5) * 16;
              return Transform.translate(
                offset: Offset(0, dy),
                child: child,
              );
            },
            child: AnimatedScale(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              scale: isCurrent ? 1.0 : 0.92,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.5),
                    ],
                  ),
                  boxShadow: [
                    // هالة خارجية زرقاء
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.12),
                      blurRadius: 40,
                      spreadRadius: 5,
                      offset: const Offset(0, 18),
                    ),
                    // هالة داخلية فاتحة
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Image.asset(
                    page.image,
                    fit: BoxFit.contain,
                    height: 240,
                    errorBuilder: (_, __, ___) => Container(
                      height: 240,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // ═══════════════════════════════════════════════
          //  العنوان — مع شريط تمييز صغير فوقه
          // ═══════════════════════════════════════════════
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: isCurrent ? 1.0 : 0.5,
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.teal, AppColors.navy],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: isCurrent ? 1.0 : 0.5,
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F2148),
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════
          //  الوصف
          // ═══════════════════════════════════════════════
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: isCurrent ? 1.0 : 0.5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF5B6B85),
                  height: 1.9,
                ),
              ),
            ),
          ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  الخلفية المتحركة الفاخرة
// ═══════════════════════════════════════════════════════════
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

    // ═══════════════════════════════════════════════════
    //  1. التدرّج الأساسي الناعم (توب-دون)
    // ═══════════════════════════════════════════════════
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

    // ═══════════════════════════════════════════════════
    //  2. دائرة زرقاء كبيرة أعلى اليسار — تدور ببطء
    // ═══════════════════════════════════════════════════
    final navyBlob = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.navy.withValues(alpha: 0.20),
          AppColors.navy.withValues(alpha: 0.0),
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
      navyBlob,
    );

    // ═══════════════════════════════════════════════════
    //  3. دائرة تركوازية كبيرة أسفل اليمين — تطفو
    // ═══════════════════════════════════════════════════
    final tealBlob = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.teal.withValues(alpha: 0.22),
          AppColors.teal.withValues(alpha: 0.0),
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

    // ═══════════════════════════════════════════════════
    //  4. دوائر صغيرة متحركة (جزيئات)
    // ═══════════════════════════════════════════════════
    _drawParticle(
      canvas,
      size,
      Offset(
        size.width * 0.15 + math.sin(t * 1.3) * 20,
        size.height * 0.30 + math.cos(t * 1.1) * 20,
      ),
      6,
      AppColors.teal.withValues(alpha: 0.35),
    );

    _drawParticle(
      canvas,
      size,
      Offset(
        size.width * 0.85 + math.cos(t * 0.9) * 25,
        size.height * 0.20 + math.sin(t * 1.2) * 20,
      ),
      8,
      AppColors.navy.withValues(alpha: 0.28),
    );

    _drawParticle(
      canvas,
      size,
      Offset(
        size.width * 0.75 + math.sin(t * 1.5) * 18,
        size.height * 0.55 + math.cos(t * 1.4) * 18,
      ),
      5,
      AppColors.yellow.withValues(alpha: 0.45),
    );

    _drawParticle(
      canvas,
      size,
      Offset(
        size.width * 0.20 + math.cos(t * 1.7) * 22,
        size.height * 0.65 + math.sin(t * 1.6) * 22,
      ),
      7,
      AppColors.pink.withValues(alpha: 0.22),
    );

    _drawParticle(
      canvas,
      size,
      Offset(
        size.width * 0.50 + math.sin(t * 0.7) * 30,
        size.height * 0.90 + math.cos(t * 0.8) * 15,
      ),
      4,
      AppColors.teal.withValues(alpha: 0.30),
    );

    // ═══════════════════════════════════════════════════
    //  5. حلقة رقيقة كبيرة — تدور ببطء شديد
    // ═══════════════════════════════════════════════════
    final ringPaint = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.65,
      ringPaint,
    );

    // ═══════════════════════════════════════════════════
    //  6. نجوم/شرارات صغيرة
    // ═══════════════════════════════════════════════════
    _drawSparkle(
      canvas,
      Offset(
        size.width * 0.10 + math.sin(t * 2) * 10,
        size.height * 0.45,
      ),
      5,
      AppColors.yellow.withValues(alpha: 0.6),
    );

    _drawSparkle(
      canvas,
      Offset(
        size.width * 0.90 + math.cos(t * 2) * 10,
        size.height * 0.42,
      ),
      5,
      AppColors.orange.withValues(alpha: 0.5),
    );
  }

  void _drawParticle(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
  ) {
    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius, paint);
  }

  void _drawSparkle(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // نجمة رباعية
    canvas.drawLine(
      Offset(center.dx, center.dy - size),
      Offset(center.dx, center.dy + size),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - size, center.dy),
      Offset(center.dx + size, center.dy),
      paint,
    );
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