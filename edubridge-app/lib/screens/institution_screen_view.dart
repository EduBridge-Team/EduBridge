part of 'institution_screen.dart';

extension _InstitutionScreenView on InstitutionScreen {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);
    final english = Localizations.localeOf(context).languageCode == 'en';

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
                  icon: Icons.apartment_rounded,
                  title: english ? 'School Management' : 'إدارة المدارس',
                  subtitle: english ? 'Schools, principals and school details' : 'المدارس ومدراؤها وبيانات كل مدرسة',
                  color: AppColors.brandBlue,
                  onTap: () => _open(context, const InstitutionOperationsScreen()),
                ),
                _ActionCard(
                  icon: Icons.bar_chart_rounded,
                  title: english ? 'Comprehensive Statistics' : 'الإحصائيات الشاملة',
                  subtitle: english ? 'School, student, teacher, and attendance reports' : 'تقارير المدارس والطلاب والمعلمين والحضور',
                  color: AppColors.brandBlue,
                  onTap: () => _open(context, const InstitutionStatisticsScreen()),
                ),
                _ActionCard(
                  icon: Icons.add_business_outlined,
                  title: english ? 'Create a school account' : 'إنشاء حساب مدرسة تابعة للمؤسسة',
                  subtitle: english ? 'Prepare login credentials for an affiliated school' : 'تجهيز حساب دخول لإحدى المدارس التابعة للمؤسسة',
                  color: AppColors.brandTeal,
                  onTap: () => _open(context, const InstitutionSchoolAccountScreen()),
                ),
                _ActionCard(
                  icon: Icons.manage_accounts_outlined,
                  title: context.l10n.directorTitle,
                  subtitle: context.l10n.directorSubtitle,
                  color: AppColors.brandBlue,
                  onTap: () => _open(context, const SchoolDirectorsScreen()),
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
              ],
            ),
          ),
        ],
      ),
    );
  
  }
}
