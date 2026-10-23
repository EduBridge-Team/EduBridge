part of 'institution_screen.dart';

extension _InstitutionScreenView on InstitutionScreen {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.appBarGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
Expanded(child: DashboardProfileIdentity(roleLabel: context.l10n.institutionRole, subtitle: context.l10n.institutionDashboardDescription)),
const SizedBox(width: 8),
DashboardHeaderActions(
                          actions: [
                            DashboardMenuAction(
                              id: 'theme',
                              label: context.l10n.switchAppearance,
                              icon: AppIcons.theme,
                              onSelected: toggleThemeMode,
                            ),
                            DashboardMenuAction(
                              id: 'legal',
                              label: context.l10n.privacyAndAccount,
                              icon: AppIcons.privacy,
                              onSelected: () =>
                                  const LegalLinksButton().show(context),
                            ),
                            DashboardMenuAction(
                              id: 'logout',
                              label: context.l10n.logout,
                              icon: AppIcons.logout,
                              destructive: true,
                              onSelected: () => _logout(context),
                            ),
                          ],
                        ),
]),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ActionCard(
                  icon: Icons.apartment_rounded,
                  title: 'إدارة المؤسسة والمدارس',
                  subtitle: 'المدارس والمعلمون والتقارير والحضور والجدول والمناهج',
                  color: AppColors.brandBlue,
                  onTap: () => _open(context, const InstitutionOperationsScreen()),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.institutionTasks,
                  style: TextStyle(
                    color: c.heading,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: AppIcons.child,
                  title: context.l10n.studentRecords,
                  subtitle: context.l10n.institutionStudentsDescription,
                  color: AppColors.brandBlue,
                  onTap: () => _open(context, const ChildrenScreen()),
                ),
                _ActionCard(
                  icon: AppIcons.lesson,
                  title: context.l10n.lessonLibrary,
                  subtitle: context.l10n.approvedContentDescription,
                  color: AppColors.brandTeal,
                  onTap: () => _open(context, const LessonsScreen()),
                ),
                _ActionCard(
                  icon: AppIcons.forum,
                  title: context.l10n.teamCommunication,
                  subtitle: context.l10n.teamCommunicationDescription,
                  color: const Color(0xFF7557BD),
                  onTap: () => _open(context, const ChatsScreen()),
                ),
                _ActionCard(
                  icon: AppIcons.verified,
                  title: context.l10n.institutionVerification,
                  subtitle: context.l10n.institutionVerificationDescription,
                  color: const Color.fromARGB(255, 17, 108, 182),
                  onTap: () => _open(context, const VerifyIdentityScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  
  }
}
