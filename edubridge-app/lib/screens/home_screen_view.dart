part of 'home_screen.dart';

extension _HomeScreenView on HomeScreen {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(34),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
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
                      const SizedBox(height: 22),
                      FutureBuilder(
                        future: Future.wait(
                          [ApiService.getName(), ApiService.getRole()],
                        ),
                        builder: (context, snapshot) {
                          final name = snapshot.data?[0];
                          final role = HomeScreen._roleNames[snapshot.data?[1]];
                          return Row(
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
                                      name != null && name.isNotEmpty
                                          ? 'مرحباً، $name'
                                          : 'مرحباً بك في EduBridge',
                                      style: textTheme.headlineSmall?.copyWith(
                                        height: 1.2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (role != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 11,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: .14,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: .16,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              role,
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ),
                                        if (role != null)
                                          const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'كل ما تحتاجه لدعم رحلة التعلّم في مكان واحد.',
                                            style: textTheme.bodySmall?.copyWith(
                                              height: 1.5,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],
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
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 30),
            sliver: SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: FutureBuilder<String?>(
                  future: ApiService.getRole(),
                  builder: (context, roleSnap) {
                    final isAdmin = roleSnap.data == 'admin';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ابدأ من هنا',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: c.heading,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'وصول سريع لأهم مساحاتك التعليمية',
                          style: textTheme.bodySmall?.copyWith(color: c.muted),
                        ),
                        const SizedBox(height: 16),
                        if (isAdmin)
                          _MenuTile(
                            icon: AppIcons.dashboard,
                            tint: isDark
                                ? const Color(0xFF103A40)
                                : AppColors.tintTeal,
                            title: 'لوحة التحكم الإدارية',
                            subtitle:
                                'إدارة المستخدمين وربط الأطفال ومتابعة المنصة',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AdminScreen(admin: {}),
                                ),
                              );
                            },
                          ),
                        _MenuTile(
                          icon: AppIcons.child,
                          tint: isDark
                              ? const Color(0xFF103A40)
                              : AppColors.tintTeal,
                          title: 'الأطفال',
                          subtitle:
                              'الملفات التعليمية والدروس والتقدّم لكل طفل',
                          onTap: () => _openChildren(context),
                        ),
                        _MenuTile(
                          icon: AppIcons.lesson,
                          tint: isDark
                              ? const Color(0xFF183B26)
                              : AppColors.tintGreen,
                          title: 'تصفّح الدروس',
                          subtitle:
                              'اكتشف المحتوى وابحث عن الدرس المناسب بسهولة',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LessonsScreen(),
                              ),
                            );
                          },
                        ),
                        _MenuTile(
                          icon: AppIcons.progress,
                          tint: isDark
                              ? const Color(0xFF45311E)
                              : AppColors.tintOrange,
                          title: 'التقدّم والمكافآت',
                          subtitle:
                              'تابع الإنجاز والنجوم والشارات في عرض واضح',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ChildrenScreen(forProgress: true),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? null
                                : LinearGradient(
                                    colors: [
                                      AppColors.tintBlue,
                                      AppColors.tintTeal.withValues(alpha: .72),
                                    ],
                                  ),
                            color: isDark ? c.card : null,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: c.line),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: AppColors.brandBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'رحلة أبسط، تركيز أكبر',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: c.heading,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'أعدنا ترتيب الواجهة لتصل للمعلومة المهمة بخطوات أقل.',
                                      style: textTheme.bodySmall?.copyWith(
                                        height: 1.45,
                                        color: c.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
