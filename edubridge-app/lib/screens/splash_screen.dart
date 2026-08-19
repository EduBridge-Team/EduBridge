import 'dart:async';
import 'package:flutter/material.dart';

/// شاشة البداية (Splash) — تظهر عند تشغيل التطبيق ثم تنتقل إلى «/home»
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // يمكن التحكم بمدة الشاشة هنا
  static const int _splashDuration = 3; // ثوانٍ

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // تنتقل إلى الشاشة الرئيسية بعد انقضاء المدة
    _timer = Timer(const Duration(seconds: _splashDuration), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          // التدرج من الأبيض إلى الأخضر الفاتح
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF0F9EE),
              Color(0xFFDDF3E0),
            ],
          ),
        ),
        child: Stack(
          children: [
            // أشكال مجردة في الخلفية (دوائر شفافة)
            const _BackgroundShapes(),
            SafeArea(
              child: Column(
                children: [
                  // شعار التطبيق أعلى الشاشة
                  const SizedBox(height: 20),
                  const _AppLogo(),
                  const Spacer(),
                  // الرسم التوضيحي الدائري
                  const _IllustrationCircle(),
                  const Spacer(),
                ],
              ),
            ),
            // النص السفلي ومؤشر التحميل
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomLoadingSection(),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================
//  مكوّن شعار التطبيق
// ==============================
class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'EDUBRIDGE',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 6,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'الجسر التعليمي',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF558B2F),
          ),
        ),
      ],
    );
  }
}

// =================================
//  الرسم التوضيحي الدائري
// =================================
class _IllustrationCircle extends StatelessWidget {
  const _IllustrationCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          // ضع ملف الرسم التوضيحي هنا
          'assets/images/splash_illustration.png',
          fit: BoxFit.cover,
          // أثناء غياب الصورة الفعلية يعرض أيقونة بديلة
          errorBuilder: (context, error, stack) => Container(
            color: const Color(0xFFE8F5E9),
            child: Icon(
              Icons.school_rounded,
              size: 120,
              color: const Color(0xFF4CAF50).withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================
//  الأشكال المجردة في الخلفية
// ==================================
class _BackgroundShapes extends StatelessWidget {
  const _BackgroundShapes();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // دائرة كبيرة أعلى اليسار
        Positioned(
          top: -80,
          left: -80,
          child: _BlurCircle(
            size: 200,
            color: const Color(0xFFA5D6A7).withValues(alpha: 0.3),
          ),
        ),
        // دائرة أسفل اليمين
        Positioned(
          bottom: 60,
          right: -50,
          child: _BlurCircle(
            size: 160,
            color: const Color(0xFF81C784).withValues(alpha: 0.2),
          ),
        ),
        // شكل صغير أعلى اليمين
        Positioned(
          top: 100,
          right: 20,
          child: _BlurCircle(
            size: 50,
            color: const Color(0xFF66BB6A).withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

// دائرة ضبابية
class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ==================================
//  القسم السفلي (جاري التحضير...)
// ==================================
class _BottomLoadingSection extends StatelessWidget {
  const _BottomLoadingSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 50, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'YOUR LEARNING JOURNEY',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: Color(0xFF33691E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          // مؤشر التحميل
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              backgroundColor: const Color(0x1F4CAF50),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري التحضير...',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF558B2F),
            ),
          ),
        ],
      ),
    );
  }
}
