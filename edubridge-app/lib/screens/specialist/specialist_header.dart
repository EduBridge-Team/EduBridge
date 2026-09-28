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
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ الصف العلوي: أفاتار + الشعار + القائمة ═══
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ProfileAvatarButton(size: 42),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/brand_icon.png',
                        width: 40, height: 40),
                    const SizedBox(width: 6),
                    const Text(
                      'EduBridge',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                DashboardMenu(actions: menuActions),
              ],
            ),
            const SizedBox(height: 12),

            // ═══ الترحيب + التخصص ═══
            FutureBuilder<String?>(
              future: ApiService.getName(),
              builder: (context, snap) {
                final name = snap.data ?? 'المختص';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً $name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitleFor(tabIndex, specialty),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
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