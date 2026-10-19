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
                gradient: AppColors.appBarGradient,
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
                          final role = HomeScreen._roleNames(context)[snapshot.data?[1]];
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
                                          ? context.l10n.dashboardGreeting(name)
                                          : context.l10n.welcomeToEduBridge,
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
                                            context.l10n.homeDashboardDescription,
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
                          context.l10n.startHere,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: c.heading,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          context.l10n.learningSpacesDescription,
                          style: textTheme.bodySmall?.copyWith(color: c.muted),
                        ),
                        const SizedBox(height: 16),
                        if (isAdmin)
                          _MenuTile(
                            icon: AppIcons.dashboard,
                            tint: isDark
                                ? const Color(0xFF103A40)
                                : AppColors.tintTeal,
                            title: context.l10n.adminDashboard,
                            subtitle:
                                context.l10n.adminDashboardDescription,
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
                          title: context.l10n.children,
                          subtitle:
                              context.l10n.childRecordsDescription,
                          onTap: () => _openChildren(context),
                        ),
                        _MenuTile(
                          icon: AppIcons.lesson,
                          tint: isDark
                              ? const Color(0xFF183B26)
                              : AppColors.tintGreen,
                          title: context.l10n.browseLessons,
                          subtitle:
                              context.l10n.browseLessonsDescription,
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
                          title: context.l10n.progressAndRewards,
                          subtitle:
                              context.l10n.progressAndRewardsDescription,
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
                                      context.l10n.simplerJourney,
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: c.heading,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      context.l10n.simplerJourneyDescription,
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
