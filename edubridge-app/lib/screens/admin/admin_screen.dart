import '../../utils/presentation_text.dart';
// lib/screens/admin/admin_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/accessibility/profile_avatar_button.dart';
import '../../widgets/dashboard_menu.dart';
import '../../widgets/legal_links_button.dart';
import '../edit_child_screen.dart';
import '../login_screen.dart';

part 'admin_users_tab.dart';
part 'admin_create_account_sheet.dart';
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

  static const _tabs = [
    (AppIcons.users, 'المستخدمون'),
    (AppIcons.shield, 'مراجعة التوثيق'),
    (AppIcons.support, 'الدعم الفني'),
  ];

  String _adminSubtitle() {
    switch (_tab) {
      case 1:
        return 'مراجعة طلبات التوثيق واعتماد الحسابات';
      case 2:
        return 'متابعة طلبات الدعم الفني';
      default:
        return 'إدارة المستخدمين وحسابات المنصة';
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

  Widget _buildAdminHeader() {
    final textTheme = Theme.of(context).textTheme;
    final menuActions = <DashboardMenuAction>[
      DashboardMenuAction(
        id: 'search_identity',
        label: 'البحث بالهوية',
        icon: AppIcons.search,
        onSelected: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchByIdentityScreen()),
        ),
      ),
      DashboardMenuAction(
        id: 'legal',
        label: 'الخصوصية والحساب',
        icon: AppIcons.privacy,
        onSelected: () => const LegalLinksButton().show(context),
      ),
      DashboardMenuAction(
        id: 'logout',
        label: 'تسجيل الخروج',
        icon: AppIcons.logout,
        destructive: true,
        onSelected: _logout,
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DashboardMenu(
                    actions: menuActions,
                    iconSize: 26,
                    iconColor: Colors.white,
                  ),
                  const Spacer(),
                  ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/brand_logo.png',
                      width: 124,
                      height: 34,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FutureBuilder<String?>(
                future: ApiService.getName(),
                builder: (context, snap) {
                  final fallbackName =
                      (widget.admin['name'] ?? widget.admin['full_name'] ?? 'الإدارة')
                          .toString();
                  final name = (snap.data ?? fallbackName).trim();
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
                              'مرحباً، ${name.isEmpty ? 'الإدارة' : name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _adminSubtitle(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                height: 1.35,
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
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
    );
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
                          'لوحة التحكم الإدارية',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: c.heading,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'إدارة المستخدمين والتوثيق وطلبات الدعم.',
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
