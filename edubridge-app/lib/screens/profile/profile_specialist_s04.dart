// S04: Figma-matched specialist profile; all displayed values come from the API.
part of 'profile_screen.dart';

extension _SpecialistS04Profile on _ProfileScreenState {
  Widget _s04Header(JisrColors c) {
    return SizedBox(
      height: BrandAppBar.standardToolbarHeight,
      child: BrandHeaderSurface(child: Stack(
        children: [
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: context.l10n.back,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .18),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const SpecialistDashboardScreen(),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    textDirection: Directionality.of(context),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    context.l10n.profile,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }

  Widget _s04Content(JisrColors c) {
    final name = (_profile?['name'] ?? '').toString();
    final email = (_profile?['email'] ?? '').toString();
    final phone = (_profile?['phone'] ?? '').toString();
    final role = (_profile?['role'] ?? '').toString();
    final isVerified = _profile?['is_verified'] == true ||
        _profile?['verification_status'] == 'verified';
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _s04Hero(name, role, isVerified),
          const SizedBox(height: 20),
          _s04Section(context.l10n.accountInformation, c),
          const SizedBox(height: 12),
          _s04InfoCard(c, name, email, phone, role, isVerified),
          if (['teacher', 'specialist'].contains(role)) ...[
          const SizedBox(height: 24),
          _s04Section(context.l10n.professionalProfile, c),
          const SizedBox(height: 12),
          if (_certificates.isEmpty)
            _s04CertificateCard(c, null)
          else
            ..._certificates.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _s04CertificateCard(c, item),
            )),
          const SizedBox(height: 8),
          _s04ActionCard(
            c,
            icon: Icons.workspace_premium_outlined,
            title: context.l10n.addCertificate,
            subtitle: context.l10n.addQualifications,
            color: AppColors.brandTealDeep,
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => AddCertificateSheet(
                onSaved: _load,
                figmaS18: true,
              ),
            ),
          ),
          ],
          const SizedBox(height: 22),
          _s04Section(context.l10n.security, c),
          const SizedBox(height: 12),
          _s04ActionCard(
            c,
            icon: Icons.lock_outline,
            title: context.l10n.changePassword,
            subtitle: context.l10n.updatePasswordDescription,
            color: AppColors.brandBlue,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
              if (result == true) _load();
            },
          ),
          const SizedBox(height: 22),
          _s04Section(context.l10n.settings, c),
          const SizedBox(height: 12),
          _s04ActionCard(
            c,
            icon: Icons.dark_mode_outlined,
            title: context.l10n.switchAppearance,
            subtitle: context.l10n.lightDarkAppearance,
            color: AppColors.brandBlue,
            onTap: () async => toggleThemeMode(),
          ),
          const SizedBox(height: 22),
          _s04Section(context.l10n.dangerZone, c),
          const SizedBox(height: 12),
          _s04ActionCard(
            c,
            icon: Icons.delete_outline,
            title: context.l10n.deleteAccountPermanently,
            subtitle: context.l10n.deleteAccountWarning,
            color: AppColors.red,
            danger: true,
            onTap: _deleting ? null : _confirmDeleteAccount,
          ),
          const SizedBox(height: 8),
          _s04ActionCard(
            c,
            icon: Icons.logout_outlined,
            title: context.l10n.signOut,
            subtitle: context.l10n.signOutDescription,
            color: AppColors.brandTealDeep,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _s04Hero(String name, String role, bool verified) {
    final initial = name.trim().isEmpty
        ? '؟'
        : name.trim().characters.first.toUpperCase();
    final avatarUrl = (_profile?['avatar_url'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF1155AD), Color(0xFF1769C2), Color(0xFF1FB8C4)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF164E87).withValues(alpha: .15),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _uploadingAvatar ? null : _showAvatarOptions,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _uploadingAvatar
                      ? const CircularProgressIndicator()
                      : avatarUrl.isEmpty
                          ? Text(initial, style: const TextStyle(
                              color: Color(0xFF1769C2),
                              fontSize: 39,
                              fontWeight: FontWeight.w800,
                            ))
                          : Image.network(
                              avatarUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                initial,
                                style: const TextStyle(
                                  color: Color(0xFF1769C2),
                                  fontSize: 39,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                ),
                Positioned(
                  right: -4,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16B6C4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: 17),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name.isEmpty ? context.l10n.user : name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .23),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _roleLabel(role),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (verified) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF58BB55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 17),
                  SizedBox(width: 5),
                  Text(context.l10n.verified,
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _s04Section(String label, JisrColors c) => Row(
    children: [
      Container(
        width: 4,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.brandTeal,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      const SizedBox(width: 9),
      Text(label, style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: c.heading,
      )),
    ],
  );

  Widget _s04InfoCard(JisrColors c, String name, String email, String phone,
      String role, bool verified) {
    final rows = <Widget>[
      _s04InfoRow(c, Icons.person_outline, context.l10n.name, name),
      _s04InfoRow(c, Icons.mail_outline, context.l10n.email, email, latin: true),
      if (phone.isNotEmpty)
        _s04InfoRow(c, Icons.phone_outlined, context.l10n.phone, phone, latin: true),
      _s04InfoRow(c, Icons.people_outline, context.l10n.role, _roleLabel(role)),
      _s04InfoRow(c, Icons.check_circle_outline, context.l10n.status,
          verified ? context.l10n.verified : context.l10n.notVerified,
          valueColor: verified ? AppColors.brandBlue : c.muted),
    ];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _s04InfoRow(JisrColors c, IconData icon, String label, String value,
      {Color? valueColor, bool latin = false}) {
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brandBlue, size: 21),
            const SizedBox(width: 9),
            Text(label, style: TextStyle(fontSize: 13, color: c.muted)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: latin ? TextAlign.left : TextAlign.end,
                textDirection: latin ? TextDirection.ltr : null,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: valueColor ?? c.heading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _s04CertificateCard(JisrColors c, dynamic certificate) {
    final data = certificate is Map ? certificate : const {};
    final title = (data['title'] ?? '').toString();
    final status = (data['status'] ?? '').toString();
    final label = status == 'verified' || status == 'approved'
        ? context.l10n.approved
        : status == 'rejected' ? context.l10n.rejected : context.l10n.awaitingReview;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_outlined,
              color: AppColors.brandBlue, size: 31),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? context.l10n.noCertificates : title,
                  style: TextStyle(
                    color: c.heading,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(color: c.muted, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _s04ActionCard(JisrColors c, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    bool danger = false,
  }) {
    return Material(
      color: danger ? AppColors.red.withValues(alpha: .065) : c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(21),
        side: BorderSide(color: danger
            ? AppColors.red.withValues(alpha: .4) : c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: danger ? AppColors.red : c.heading,
                      fontSize: 15.5,
                    )),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(
                      color: c.muted,
                      fontSize: 13,
                    )),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: c.muted, size: 21),
            ],
          ),
        ),
      ),
    );
  }

  Widget _s04BottomNavigation(JisrColors c) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(
          color: Color(0xFF8FA5B5), width: 1.5)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: c.card,
          indicatorColor: const Color(0xFFE1F0FF),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800 : FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? AppColors.brandBlue : c.muted,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 23,
              color: states.contains(WidgetState.selected)
                  ? AppColors.brandBlue : c.muted,
            ),
          ),
        ),
        child: NavigationBar(
          height: 76,
          selectedIndex: 0,
          onDestinationSelected: (index) {
            if (index == 0) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const SpecialistDashboardScreen(),
                ),
                (_) => false,
              );
              return;
            }
            final Widget destination;
            switch (index) {
              case 1:
                destination = const CaseDiscussionScreen();
                break;
              case 2:
                destination = const ChatsScreen();
                break;
              case 3:
                destination = const LearningSupportRequestsScreen();
                break;
              default:
                return;
            }
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => destination),
            );
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded),
              label: context.l10n.children,
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              label: context.l10n.caseStudies,
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              label: context.l10n.conversations,
            ),
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              label: context.l10n.supportRequests,
            ),
          ],
        ),
      ),
    );
  }
}
