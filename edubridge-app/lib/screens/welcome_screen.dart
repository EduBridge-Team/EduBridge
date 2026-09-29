// lib/screens/welcome_screen.dart
// الشاشة الترحيبية — بهوية EduBridge
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../theme.dart';
import '../services/onboarding_service.dart';
import 'login_screen.dart';

part 'welcome_page_content.dart';
part 'welcome_background.dart';

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

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

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
    if (i == _pages.length - 1) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  Future<void> _goToLogin() async {
    await OnboardingService.markSeen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          _AnimatedBackground(controller: _bgController),
          SafeArea(
            child: Column(
              children: [
                // ─── زر Skip ───
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                    child: TextButton(
                      onPressed: _goToLogin,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brandBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        backgroundColor:
                            Colors.white.withValues(alpha: .82),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: AppColors.brandBlue.withValues(alpha: .14),
                          ),
                        ),
                      ),
                      child: const Text(
                        'تخطي',
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

                // ─── النقاط ───
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.brandBlue
                              : AppColors.brandBlue.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: AppColors.brandBlue
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

                // ─── زر ابدأ ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                        height: 56,
                        child: FilledButton(
                          onPressed: _isLastPage ? _goToLogin : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor: Colors.transparent,
                            elevation: 2,
                            shadowColor:
                                AppColors.brandBlue.withValues(alpha: 0.16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ابدأ',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
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

}
