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
            child: BrandDashboardHeader(child: Row(children: [
              Expanded(child: FutureBuilder<String?>(
                future: ApiService.getRole(),
                builder: (context, snapshot) => DashboardProfileIdentity(
                  roleLabel: HomeScreen._roleNames(context)[snapshot.data] ?? context.l10n.parentRole,
                  subtitle: context.l10n.homeDashboardDescription,
                ),
              )),
              const SizedBox(width: 8),
              DashboardMenu(iconSize: 26, iconColor: Colors.white, actions: [
                DashboardMenuAction(id: 'legal', label: context.l10n.privacyAndAccount,
                  icon: AppIcons.privacy,
                  onSelected: () => const LegalLinksButton().show(context)),
                DashboardMenuAction(id: 'logout', label: context.l10n.logout,
                  icon: AppIcons.logout, destructive: true,
                  onSelected: () => _logout(context)),
              ]),
            ])),
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
                                      const AdminScreen(admin: {'role': 'admin'}),
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
