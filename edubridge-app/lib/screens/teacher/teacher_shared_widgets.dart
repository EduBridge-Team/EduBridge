// lib/screens/teacher/teacher_shared_widgets.dart
part of 'teacher_screen.dart';

Widget _buildTeacherHeader({
  required BuildContext context,
  required JisrColors c,
  required int tabIndex,
  required int childrenCount,
  required Future<void> Function() onLogout,
  required Future<bool> Function() onVerify,
  required Future<void> Function() onLoadData,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DashboardMenu(
                  iconSize: 26,
                  iconColor: Colors.white,
                  actions: [
                    DashboardMenuAction(id: 'notifications', label: 'الإشعارات', icon: AppIcons.notifications,
                      onSelected: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                    DashboardMenuAction(
                      id: 'case_discussion',
                      label: 'دراسات الحالة',
                      icon: AppIcons.forum,
                      onSelected: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CaseDiscussionScreen()),
                      ),
                    ),
                    DashboardMenuAction(
                      id: 'support',
                      label: 'الدعم الفني',
                      icon: AppIcons.support,
                      onSelected: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const SupportSheet(),
                      ),
                    ),
                    DashboardMenuAction(
                      id: 'chats',
                      label: 'المحادثات',
                      icon: AppIcons.chat,
                      onSelected: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatsScreen()),
                      ),
                    ),
                    DashboardMenuAction(
                      id: 'legal',
                      label: 'الخصوصية والحساب',
                      icon: AppIcons.privacy,
                      onSelected: () => const LegalLinksButton().show(context),
                    ),
                    DashboardMenuAction(
                      id: 'logout',
                      label: 'تسجيل الخروج',
                      icon: AppIcons.logout,
                      destructive: true,
                      onSelected: () => onLogout(),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
              ],
            ),
            const SizedBox(height: 18),
            FutureBuilder<String?>(
              future: ApiService.getName(),
              builder: (context, snap) {
                final name = snap.data ?? 'المعلم';
                final subtitle = switch (tabIndex) {
                  0 => 'لديك $childrenCount طفل${childrenCount != 1 ? 'اً' : ''} تحت مسؤوليتك',
                  1 => 'أضف دروساً جديدة أو تصفّح الدروس الموجودة',
                  _ => 'تابع الواجبات والتسليمات والتصحيح',
                };
                return Row(
                  children: [
                    const ProfileAvatarButton(size: 54),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('مرحباً، $name',
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              )),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
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

Widget _buildTeacherError(String error, Future<void> Function() reload) {
  return ListView(
    children: [
      const SizedBox(height: 80),
      Center(
        child: Column(
          children: [
            Text(error, style: const TextStyle(fontSize: 16, color: AppColors.red)),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(AppIcons.refresh, size: 28),
                label: const Text('إعادة المحاولة', style: TextStyle(fontSize: 18)),
                onPressed: reload,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
