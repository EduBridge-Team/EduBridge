import '../l10n/l10n.dart';
import '../utils/presentation_text.dart';
// lib/screens/parent_screen.dart
// لوحة ولي الأمر — بهوية EduBridge
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/accessibility/adaptive_text.dart';
import '../widgets/accessibility/adaptive_wrapper.dart';
import '../widgets/legal_links_button.dart';
import '../widgets/dashboard_menu.dart';
import '../widgets/dashboard_header_actions.dart';
import '../widgets/dashboard_profile_identity.dart';
import 'add_child/add_child_screen.dart';
import 'notifications_screen.dart';
import 'support_sheet.dart';
import 'chats_screen.dart';
import 'parent_lessons_screen.dart';
import 'parent_child_profile_screen.dart';
import 'parent_navigation_bar.dart';
import 'profile/profile_screen.dart';
import 'login_screen.dart';

part 'parent_screen_widgets.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  List _children = [];
  int _tabIndex = 0;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _refreshData() => _loadData(showLoader: false);

  Future<void> _loadData({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _hasError = false;
      });
    } else if (_hasError) {
      setState(() => _hasError = false);
    }

    try {
      final res = await ApiService.authGet('/children');
      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _children = data['children'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  Future<void> _openChildDetails(Map child) async {
    final id = child['id'];
    if (id is! int || id <= 0) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ParentChildProfileScreen(child: child, childId: id),
      ),
    );
    if (mounted) await _refreshData();
  }

  Future<void> _openAddChild() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddChildScreen()),
    );
    if (mounted && result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveWrapper(
      screenTitle: context.l10n.parentDashboard,
      child: Scaffold(
        appBar: _tabIndex == 0 ? _buildAppBar() : null,
        body: switch (_tabIndex) {
          1 => const ParentLessonsScreen(inParentTabs: true),
          2 => const ChatsScreen(inParentTabs: true),
          3 => const ProfileScreen(inParentTabs: true),
          _ => RefreshIndicator(onRefresh: _refreshData, child: _buildBody()),
        },
        bottomNavigationBar: ParentNavigationBar(
          selectedIndex: _tabIndex,
          onSelected: (index) => setState(() => _tabIndex = index),
        ),
        floatingActionButton: _tabIndex == 0
            ? FloatingActionButton.extended(
                onPressed: _openAddChild,
                icon: const Icon(AppIcons.add),
                label: Text(
                  context.l10n.addChild,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return BrandAppBar(
      titleSpacing: 0,
      centerTitle: false,
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      title: Padding(
          padding: const EdgeInsetsDirectional.only(start: 18),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: DashboardProfileIdentity(roleLabel: context.l10n.parentRole, subtitle: context.l10n.parentDashboardDescription),
          ),
        ),
      actions: [
        DashboardHeaderActions(
            showMicrophoneToggle: true,
            actions: [
              DashboardMenuAction(
                id: 'notifications',
                label: context.l10n.notifications,
                icon: AppIcons.notifications,
                onSelected: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              DashboardMenuAction(
                id: 'support',
                label: context.l10n.technicalSupport,
                icon: AppIcons.support,
                onSelected: () => SupportSheet.show(context),
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
                onSelected: () async {
                  final navigator = Navigator.of(context);
                  await ApiService.logout();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        const SizedBox(width: 18),
      ],
    );
  }
}
