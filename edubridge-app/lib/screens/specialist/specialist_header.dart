// lib/screens/specialist/specialist_header.dart
part of 'specialist_screen.dart';

Widget _buildHeader(
  BuildContext context,
  JisrColors c,
  int tabIndex,
  String? specialty,
) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ProfileAvatarButton(size: 42),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/brand_icon.png', width: 40, height: 40),
                    const SizedBox(width: 6),
                    const Text('EduBridge',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                  ],
                ),
                DashboardMenu(
                  actions: [
                    DashboardMenuAction(
                      id: 'case_discussion',
                      label: 'دراسات الحالة',
                      icon: AppIcons.forum,
                      onSelected: () =>
                          Navigator.pushNamed(context, '/case_discussion'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<String?>(
              future: ApiService.getName(),
              builder: (context, snap) {
                final name = snap.data ?? 'المختص';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحباً $name',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    Text(
                      tabIndex == 0
                          ? 'نظرة عامة على الأطفال'
                          : 'أضف دروساً لأولياء الأمور وللأطفال',
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