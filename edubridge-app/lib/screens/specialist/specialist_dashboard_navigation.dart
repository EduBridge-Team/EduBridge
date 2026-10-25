import 'package:flutter/material.dart';

import '../../app_icons.dart';
import '../../l10n/l10n.dart';
import '../../widgets/dashboard_menu.dart';
import '../../widgets/legal_links_button.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../chats_screen.dart';
import '../learning_support_requests/learning_support_requests_screen.dart';
import '../support_sheet.dart';

/// Builds dashboard menu actions from callbacks and shared destinations.
List<DashboardMenuAction> specialistDashboardMenuActions({
  required BuildContext context,
  required String searchQuery,
  required VoidCallback onLessons,
  required VoidCallback onSearch,
  required VoidCallback onAddCertificate,
  required VoidCallback onLogout,
}) {
  return [
    DashboardMenuAction(
      id: 'specialist_lessons',
      label: context.l10n.lessons,
      icon: AppIcons.lesson,
      onSelected: onLessons,
    ),
    DashboardMenuAction(
      id: 'search_children',
      label: searchQuery.isEmpty
          ? context.l10n.searchForChild
          : context.l10n.editChildSearch,
      icon: AppIcons.search,
      onSelected: onSearch,
    ),
    DashboardMenuAction(
      id: 'case_discussion',
      label: context.l10n.caseStudies,
      icon: AppIcons.forum,
      onSelected: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CaseDiscussionScreen()),
      ),
    ),
    DashboardMenuAction(
      id: 'support_requests',
      label: context.l10n.supportRequests,
      icon: AppIcons.specialist,
      onSelected: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LearningSupportRequestsScreen(),
        ),
      ),
    ),
    DashboardMenuAction(
      id: 'add_certificate',
      label: context.l10n.addCertificate,
      icon: AppIcons.certificate,
      onSelected: onAddCertificate,
    ),
    DashboardMenuAction(
      id: 'chats',
      label: context.l10n.conversations,
      icon: AppIcons.chat,
      onSelected: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatsScreen()),
      ),
    ),
    DashboardMenuAction(
      id: 'support',
      label: context.l10n.technicalSupport,
      icon: AppIcons.support,
      onSelected: () => SupportSheet.show(context),
    ),
    DashboardMenuAction(
      id: 'about_app',
      label: context.l10n.aboutApp,
      icon: Icons.info_outline,
      onSelected: () => showAboutDialog(
        context: context,
        applicationName: 'EduBridge',
        children: [Text(context.l10n.aboutEduBridge)],
      ),
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
      onSelected: onLogout,
    ),
  ];
}

void openSpecialistDashboardDestination(
  BuildContext context,
  int index, {
  required VoidCallback onChildren,
}) {
  if (index == 0) {
    onChildren();
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
  Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
}
