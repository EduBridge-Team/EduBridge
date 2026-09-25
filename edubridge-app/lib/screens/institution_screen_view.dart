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
                        Container(
                          width: 42,
                          height: 42,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Image.asset('assets/brand_icon.png'),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'لوحة المؤسسة التعليمية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        DashboardMenu(
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
                      ],
                    ),
                    const SizedBox(height: 18),
                    FutureBuilder<String?>(
                      future: ApiService.getName(),
                      builder: (context, snapshot) => Text(
                        'أهلاً، ${snapshot.data?.isNotEmpty == true ? snapshot.data : 'فريق المؤسسة'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'أدر الفريق وتابع الحالات والمحتوى من مساحة واحدة.',
                      style: TextStyle(color: Color(0xFFDDF7FF), fontSize: 15),
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
                  color: const Color(0xFFB77318),
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
