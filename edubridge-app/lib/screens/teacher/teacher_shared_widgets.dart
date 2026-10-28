// lib/screens/teacher/teacher_shared_widgets.dart
part of 'teacher_screen.dart';

Widget _buildTeacherHeader({
  required BuildContext context,
  required JisrColors c,
  required int tabIndex,
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
Expanded(child: DashboardProfileIdentity(roleLabel: context.l10n.teacherRole, subtitle: switch (tabIndex) { 0 => Localizations.localeOf(context).languageCode == 'en' ? 'Your assigned sections and their students' : 'شُعبك المكلّف بها وطلاب كل شعبة', 1 => context.l10n.teacherLessonsDescription, _ => context.l10n.teacherHomeworkDescription })),
const SizedBox(width: 8),
DashboardHeaderActions(
                  actions: [
                    DashboardMenuAction(
                      id: 'notifications',
                      label: context.l10n.notifications,
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
                      label: context.l10n.caseStudies,
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
                      label: context.l10n.technicalSupport,
                      icon: AppIcons.support,
                      onSelected: () => SupportSheet.show(context),
                    ),
                    DashboardMenuAction(
                      id: 'chats',
                      label: context.l10n.conversations,
                      icon: AppIcons.chat,
                      onSelected: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatsScreen()),
                      ),
                    ),
                    DashboardMenuAction(
                      id: 'legal',
                      label: context.l10n.privacyAndAccount,
                      icon: AppIcons.privacy,
                      onSelected: () => const LegalLinksButton().show(context),
                    ),
                    DashboardMenuAction(
                      id: 'logout',
                      label: context.l10n.logout,
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

Widget _buildTeacherError(Object error, Future<void> Function() reload) {
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
                  context.sharedMessage(error),
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.red),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(AppIcons.refresh, size: 28),
                    label: Text(
                      context.l10n.retryAction,
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
