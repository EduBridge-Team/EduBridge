// lib/screens/specialist/specialist_header.dart
part of 'specialist_screen.dart';

Widget _buildHeader({
  required BuildContext context,
  required JisrColors c,
  required int tabIndex,
  required String? specialty,
  required List<DashboardMenuAction> menuActions,
}) {
  return Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: AppColors.headerGradient,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصف العلوي موحّد: القائمة يميناً والشعار الأبيض يساراً.
            Row(
              children: [
                DashboardMenu(
                  actions: menuActions,
                  iconSize: 26,
                  iconColor: Colors.white,
                ),
                const Spacer(),
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/brand_logo.png',
                    width: 136,
                    height: 38,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ═══ الترحيب + التخصص ═══
            FutureBuilder<String?>(
              future: ApiService.getName(),
              builder: (context, snap) {
                final name = snap.data ?? 'المختص';
                return Row(
                  children: [
                    const ProfileAvatarButton(
                      size: 54,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brandTealDeep,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً، $name',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _subtitleFor(tabIndex, specialty),
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  سطر فرعي ذكي — يعرض التخصص في تبويب التقدم
// ═══════════════════════════════════════════════════════════
String _subtitleFor(int tabIndex, String? specialty) {
  if (tabIndex == 1) {
    return 'أضف دروساً لأولياء الأمور وللأطفال';
  }

  switch (specialty) {
    case 'learning_support':
      return 'مختص دعم تعليمي • نظرة عامة على الأطفال';
    case 'educational':
      return 'مختص تعليمي • نظرة عامة على الأطفال';
    default:
      return 'نظرة عامة على الأطفال';
  }
}