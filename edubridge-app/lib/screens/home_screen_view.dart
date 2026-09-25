part of 'home_screen.dart';

extension _HomeScreenView on HomeScreen {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      body: Column(
        children: [
          // ═══ الهيدر ═══
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
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset('assets/brand_icon.png',
                              width: 36, height: 36),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'EduBridge',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
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
                    const SizedBox(height: 14),
                    FutureBuilder(
                      future: Future.wait(
                          [ApiService.getName(), ApiService.getRole()]),
                      builder: (context, snapshot) {
                        final name = snapshot.data?[0];
                        final role = _roleNames[snapshot.data?[1]];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'مرحباً بك',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.white70),
                            ),
                            Text(
                              [
                                if (name != null && name.isNotEmpty) name,
                                if (role != null) '— $role',
                              ].join(' '),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
          ),

          // ═══ القائمة ═══
          Expanded(
            child: FutureBuilder<String?>(
              future: ApiService.getRole(),
              builder: (context, roleSnap) {
                final isAdmin = roleSnap.data == 'admin';
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (isAdmin)
                      _MenuTile(
                        icon: AppIcons.dashboard,
                        tint: c.tintTeal,
                        title: 'لوحة التحكم الإدارية',
                        subtitle: 'إدارة المستخدمين وربط الأطفال بأولياء الأمور',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminScreen(admin: {})),
                          );
                        },
                      ),
                    _MenuTile(
                      icon: AppIcons.child,
                      tint: c.tintTeal,
                      title: 'الأطفال',
                      subtitle: 'عرض الأطفال ودروسهم وتقدّمهم',
                      onTap: () => _openChildren(context),
                    ),
                    _MenuTile(
                      icon: AppIcons.lesson,
                      tint: c.tintGreen,
                      title: 'تصفح الدروس',
                      subtitle: 'كل الدروس مع بحث',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LessonsScreen()),
                        );
                      },
                    ),
                    _MenuTile(
                      icon: AppIcons.progress,
                      tint: c.tintOrange,
                      title: 'التقدّم والمكافآت',
                      subtitle: 'ملخّص الإنجاز والنجوم وشارات كل طفل',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ChildrenScreen(forProgress: true)),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  
  }
}
