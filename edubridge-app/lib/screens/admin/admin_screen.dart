import '../school_management/school_admin_directory_screen.dart';
import '../../l10n/l10n.dart';
import '../../utils/presentation_text.dart';
// lib/screens/admin/admin_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/dashboard_menu.dart';
import '../../widgets/dashboard_header_actions.dart';
import '../../widgets/dashboard_profile_identity.dart';
import '../../widgets/legal_links_button.dart';
import '../edit_child_screen.dart';
import '../login_screen.dart';
import 'admin_school_create_page.dart';

part 'admin_users_tab.dart';
part 'admin_account_type_dialog.dart';
part 'admin_create_account_page.dart';
part 'admin_user_children_sheet.dart';
part 'admin_user_tiles.dart';
part 'admin_shared_widgets.dart';
part 'admin_verification_tab.dart';
part 'admin_support_tab.dart';
part 'admin_edit_user_sheet.dart';
part 'admin_search_screen.dart';
part 'admin_users_tab_view.dart';

class AdminScreen extends StatefulWidget {
  final Map admin;
  const AdminScreen({super.key, required this.admin});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;

  List<(IconData, String)> get _tabs => [
    (AppIcons.users, context.l10n.users),
    (AppIcons.shield, context.l10n.verificationReview),
    (AppIcons.support, context.l10n.technicalSupport),
  ];

  String _adminSubtitle() {
    switch (_tab) {
      case 1:
        return context.l10n.adminVerificationDescription;
      case 2:
        return context.l10n.adminSupportDescription;
      default:
        return context.l10n.adminUsersDescription;
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openAccountPage(String role) async {
    if ((widget.admin['role'] ?? '').toString() != 'admin') return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _AdminCreateAccountPage(role: role)),
    );
  }

  Future<void> _showAccountTypeDialog() async {
    if ((widget.admin['role'] ?? '').toString() != 'admin') return;
    final role = await showDialog<String>(
      context: context,
      builder: (_) => const _AdminAccountTypeDialog(),
    );
    if (!mounted || role == null) return;
    if (role == 'school') {
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AdminSchoolCreatePage()),
      );
    } else {
      await _openAccountPage(role);
    }
  }

  Widget _buildAdminHeader() {
    final menuActions = <DashboardMenuAction>[
      DashboardMenuAction(id: 'school-directory', label: Localizations.localeOf(context).languageCode == 'en' ? 'School administration' : 'إدارة المدارس', icon: Icons.school_outlined, onSelected: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SchoolAdminDirectoryScreen()))),
      DashboardMenuAction(
        id: 'search_identity',
        label: context.l10n.searchByIdentity,
        icon: AppIcons.search,
        onSelected: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchByIdentityScreen()),
        ),
      ),
      if ((widget.admin['role'] ?? '').toString() == 'admin')
        DashboardMenuAction(
          id: 'create_accounts',
          label: Localizations.localeOf(context).languageCode == 'ar'
              ? 'إنشاء حسابات'
              : 'Create accounts',
          icon: Icons.person_add_alt_1_outlined,
          onSelected: _showAccountTypeDialog,
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
        onSelected: _logout,
      ),
    ];

    return BrandDashboardHeader(child: Row(children: [
Expanded(child: DashboardProfileIdentity(roleLabel: context.l10n.adminRole, subtitle: _adminSubtitle())),
const SizedBox(width: 8),
DashboardHeaderActions(
                    actions: menuActions,
                    menuIcon: Icons.menu_rounded,
                  ),
]));
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAdminHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: c.tintTeal,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      AppIcons.settings,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.adminDashboard,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: c.heading,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.l10n.adminManagementDescription,
                          style: textTheme.bodySmall?.copyWith(color: c.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _AdminTabBar(
              tabs: _tabs,
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _tab == 0
                ? _UsersTab(admin: widget.admin)
                : _tab == 1
                    ? const _VerificationTab()
                    : _SupportTicketsTab(admin: widget.admin),
          ),
        ],
      ),
    );
  }
}

class _AdminTabBar extends StatelessWidget {
  final List<(IconData, String)> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  const _AdminTabBar({
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == selected;
          final (icon, label) = tabs[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.brandBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.brandBlue.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: active ? Colors.white : c.muted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : c.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
