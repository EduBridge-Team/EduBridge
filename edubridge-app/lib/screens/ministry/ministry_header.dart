// lib/screens/ministry/ministry_header.dart
part of 'ministry_screen.dart';

class _MinistryHeader extends StatelessWidget {
  const _MinistryHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.appBarGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return Row(children: [
Expanded(child: DashboardProfileIdentity(roleLabel: 'الوزارة', subtitle: 'إدارة شاملة للمؤسسات والموافقات')),
const SizedBox(width: 8),
DashboardHeaderActions(
          actions: [
            DashboardMenuAction(
              id: 'support',
              label: 'الدعم الفني',
              icon: AppIcons.support,
              onSelected: () => SupportSheet.show(context),
            ),
            DashboardMenuAction(
              id: 'chats',
              label: 'المحادثات',
              icon: AppIcons.chat,
              onSelected: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatsScreen()),
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
