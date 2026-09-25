// lib/screens/teacher/teacher_shared_widgets.dart
part of 'teacher_screen.dart';

Widget _buildTeacherHeader({
  required BuildContext context,
  required JisrColors c,
  required int tabIndex,
  required int childrenCount,
  required Future<void> Function() onLogout,
  required Future<void> Function() onOpenHomework,
  required Future<bool> Function() onVerify,
  required Future<void> Function() onLoadData,
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
                      onSelected: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CaseDiscussionScreen()),
                      ),
                    ),
                    DashboardMenuAction(
                      id: 'create_homework',
                      label: 'إضافة واجب',
                      icon: AppIcons.homework,
                      onSelected: () => onOpenHomework(),
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
                      id: 'certificate',
                      label: 'إضافة شهادة',
                      icon: AppIcons.certificate,
                      onSelected: () async {
                        if (await onVerify()) {
                          if (!context.mounted) return;
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                AddCertificateSheet(onSaved: onLoadData),
                          );
                        }
                      },
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
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<String?>(
              future: ApiService.getName(),
              builder: (context, snap) {
                final name = snap.data ?? 'المعلم';
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
                          ? 'لديك $childrenCount طفل${childrenCount != 1 ? 'اً' : ''} تحت مسؤوليتك'
                          : 'أضف دروساً جديدة أو صفّح الدروس الموجودة',
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