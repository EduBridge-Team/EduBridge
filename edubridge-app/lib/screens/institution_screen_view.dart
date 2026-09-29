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
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DashboardMenu(
                          iconSize: 26,
                          iconColor: Colors.white,
                          actions: [
                            DashboardMenuAction(
                              id: 'theme',
                              label: 'تبديل وضع العرض',
                              icon: AppIcons.theme,
                              onSelected: toggleThemeMode,
                            ),
                            DashboardMenuAction(
                              id: 'legal',
                              label: 'الخصوصية والحساب',
                              icon: AppIcons.privacy,
                              onSelected: () =>
                                  const LegalLinksButton().show(context),
                            ),
                            DashboardMenuAction(
                              id: 'logout',
                              label: 'تسجيل الخروج',
                              icon: AppIcons.logout,
                              destructive: true,
                              onSelected: () => _logout(context),
                            ),
                          ],
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
                    FutureBuilder<String?>(
                      future: ApiService.getName(),
                      builder: (context, snapshot) => Row(
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
                                  'مرحباً، ${snapshot.data?.isNotEmpty == true ? snapshot.data : 'فريق المؤسسة'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'أدر الفريق وتابع الحالات والمحتوى من مساحة واحدة.',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Colors.white.withValues(alpha: .86),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: AppIcons.users,
                        value: '٢٤',
                        label: 'عضوًا بالفريق',
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: AppIcons.check,
                        value: '١٨',
                        label: 'حالة نشطة',
                        color: AppColors.brandTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'مهام المؤسسة',
                  style: TextStyle(
                    color: c.heading,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: AppIcons.child,
                  title: 'ملفات الطلاب',
                  subtitle: 'عرض الطلاب والحالات المرتبطة بالمؤسسة',
                  color: AppColors.brandBlue,
                  onTap: () => _open(context, const ChildrenScreen()),
                ),
                _ActionCard(
                  icon: AppIcons.lesson,
                  title: 'مكتبة الدروس',
                  subtitle: 'الوصول إلى المحتوى التعليمي المعتمد',
                  color: AppColors.brandTeal,
                  onTap: () => _open(context, const LessonsScreen()),
                ),
                _ActionCard(
                  icon: AppIcons.forum,
                  title: 'تواصل الفريق',
                  subtitle: 'محادثات المعلمين والمختصين',
                  color: const Color(0xFF7557BD),
                  onTap: () => _open(context, const ChatsScreen()),
                ),
                _ActionCard(
                  icon: AppIcons.verified,
                  title: 'توثيق المؤسسة',
                  subtitle: 'متابعة حالة الهوية والصلاحيات',
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
