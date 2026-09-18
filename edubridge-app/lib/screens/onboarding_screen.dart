// lib/screens/onboarding_screen.dart
// 3 واجهات ترحيبية (Onboarding) — تُعرض أول مرة فقط
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

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
      image: '',
      title: 'خطوة بخطوة نحو إمكاناته',
      subtitle:
          'نرافق طفلك في رحلة تعليمية ممتعة، مصممة لتناسب قدراته وتساعده على الوصول إلى أهدافه.',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ الانتقال لتسجيل الدخول (يُستدعى من Skip أو "ابدأ الآن")
  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ✅ الانتقال للصفحة التالية
  void _nextPage() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Column(
          children: [
            // ═══════════════════════════════════════════════
            //  زر Skip صغير على الجانب (دائماً ظاهر)
            // ═══════════════════════════════════════════════
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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

            // ═══════════════════════════════════════════════
            //  الصفحات — السحب يعمل
            // ═══════════════════════════════════════════════
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _buildPage(_pages[i]),
              ),
            ),

            // ═══════════════════════════════════════════════
            //  النقاط الدلالية
            // ═══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.navy
                          : AppColors.navy.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // ═══════════════════════════════════════════════
            //  زر سفلي — يتغير حسب الصفحة
            //  - الصفحات 1-2: "التالي" (اختياري)
            //  - الصفحة 3: "ابدأ الآن" ✅
            // ═══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLastPage ? _finish : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isLastPage ? 'ابدأ الآن' : 'التالي',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  بناء صفحة واحدة
  // ═══════════════════════════════════════════════════
  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // بطاقة الصورة
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Image.asset(
              page.image,
              fit: BoxFit.contain,
              height: 260,
              errorBuilder: (_, __, ___) => Container(
                height: 260,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),

          // العنوان
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F2148),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // الوصف
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF5B6B85),
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
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