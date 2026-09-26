// lib/screens/ministry/ministry_screen.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../services/approval_service.dart';
import '../../theme.dart';
import '../../widgets/legal_links_button.dart';
import '../../widgets/dashboard_menu.dart';
import '../../widgets/accessibility/profile_avatar_button.dart';
import '../admin/admin_screen.dart';
import '../chats_screen.dart';
import '../lessons_screen.dart';
import '../support_sheet.dart';

part 'ministry_header.dart';
part 'ministry_tab_bar.dart';
part 'ministry_overview_tab.dart';
part 'ministry_approvals_tab.dart';
part 'ministry_approval_widgets.dart';
part 'ministry_users_tab.dart';
part 'ministry_users_tab_view.dart';

class MinistryScreen extends StatefulWidget {
  const MinistryScreen({super.key});

  @override
  State<MinistryScreen> createState() => _MinistryScreenState();
}

class _MinistryScreenState extends State<MinistryScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      body: Column(
        children: [
          _MinistryHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _MinistryTabBar(
              index: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
          ),
          Expanded(
            child: _tabIndex == 0
                ? const _MinistryOverviewTab()
                : _tabIndex == 1
                    ? const _MinistryApprovalsTab()
                    : const _MinistryUsersTab(),
          ),
        ],
      ),
    );
  }
}