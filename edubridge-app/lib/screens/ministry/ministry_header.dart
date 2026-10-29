// lib/screens/ministry/ministry_header.dart
part of 'ministry_screen.dart';

class _MinistryHeader extends StatelessWidget {
  const _MinistryHeader();

  @override
  Widget build(BuildContext context) {
    return BrandDashboardHeader(child: _buildTopRow(context));
  }

  Widget _buildTopRow(BuildContext context) {
    return Row(children: [
Expanded(child: DashboardProfileIdentity(roleLabel: context.l10n.ministryRole, subtitle: context.l10n.ministryDashboardDescription)),
const SizedBox(width: 8),
DashboardHeaderActions(
          actions: [
            DashboardMenuAction(
              id: 'support',
              label: context.l10n.technicalSupport,
              icon: AppIcons.support,
              onSelected: () => SupportSheet.show(context),
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
]);
  }

}
