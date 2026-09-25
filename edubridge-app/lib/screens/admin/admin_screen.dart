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

part 'admin_users_tab.dart';
part 'admin_user_children_sheet.dart';
part 'admin_user_tiles.dart';
part 'admin_shared_widgets.dart';
part 'admin_verification_tab.dart';
part 'admin_support_tab.dart';
part 'admin_edit_user_sheet.dart';
part 'admin_search_screen.dart';

class AdminScreen extends StatefulWidget {
  final Map admin;
  const AdminScreen({super.key, required this.admin});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;

  static const _tabs = [
    (AppIcons.users,   'المستخدمون'),
    (AppIcons.shield,  'مراجعة التوثيق'),
    (AppIcons.support, 'الدعم الفني'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
        title: const Text(
          'لوحة التحكم الإدارية',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.search, color: Colors.white),
            tooltip: 'البحث بالهوية',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchByIdentityScreen()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: ProfileAvatarButton(size: 38, backgroundColor: Colors.white),
            ),
          ),
          DashboardMenu(
            actions: [
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
                onSelected: () async {
                  await ApiService.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(AppIcons.settings, size: 24, color: c.heading),
                const SizedBox(width: 8),
                Text(
                  'لوحة التحكم الإدارية',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c.heading),
                ),
              ],
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

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(999),
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
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.brandBlue.withValues(alpha: 0.45),
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
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
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