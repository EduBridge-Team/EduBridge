// Onboarding page content extracted from welcome_screen.dart.
part of 'welcome_screen.dart';

extension _WelcomePageContentExtension on _WelcomeScreenState {
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
                // ─── الصورة ───
                AnimatedBuilder(
                  animation: _floatController,
                  builder: (context, child) {
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
                          BoxShadow(
                            color: AppColors.brandBlue.withValues(alpha: 0.12),
                            blurRadius: 40,
                            spreadRadius: 5,
                            offset: const Offset(0, 18),
                          ),
                          BoxShadow(
                            color: AppColors.brandTeal.withValues(alpha: 0.08),
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
                              AppIcons.image,
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

                // ─── الشريط ───
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: isCurrent ? 1.0 : 0.5,
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.brandTeal, AppColors.brandBlue],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ─── العنوان ───
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: isCurrent ? 1.0 : 0.5,
                  child: Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── الوصف ───
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
                        color: AppColors.muted,
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
