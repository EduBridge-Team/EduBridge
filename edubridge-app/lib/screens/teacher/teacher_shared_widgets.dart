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
      gradient: AppColors.appBarGradient,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
Expanded(child: DashboardProfileIdentity(roleLabel: 'المعلم', subtitle: switch (tabIndex) { 0 => 'لديك $childrenCount طفل تحت مسؤوليتك', 1 => 'أضف دروساً جديدة أو تصفّح الدروس الموجودة', _ => 'تابع الواجبات والتسليمات والتصحيح' })),
const SizedBox(width: 8),
DashboardHeaderActions(
                  actions: [
                    DashboardMenuAction(
                      id: 'notifications',
                      label: 'الإشعارات',
                      icon: AppIcons.notifications,
                      onSelected: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                    DashboardMenuAction(
                      id: 'case_discussion',
                      label: 'دراسات الحالة',
                      icon: AppIcons.forum,
                      onSelected: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CaseDiscussionScreen(),
                        ),
                      ),
                    ),
                    DashboardMenuAction(
                      id: 'support',
                      label: 'الدعم الفني',
                      icon: AppIcons.support,
                      onSelected: () => SupportSheet.show(context),
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
]),
          ],
        ),
      ),
    ),
  );
}

Widget _buildTeacherError(String error, Future<void> Function() reload) {
  return Builder(
    builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Text(
                  error,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.red),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(AppIcons.refresh, size: 28),
                    label: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(fontSize: 18),
                    ),
                    onPressed: reload,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
