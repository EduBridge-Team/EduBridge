// lib/screens/ministry/ministry_header.dart
part of 'ministry_screen.dart';

class _MinistryHeader extends StatelessWidget {
  const _MinistryHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
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
              const SizedBox(height: 12),
              _buildGreeting(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/brand_icon.png', width: 32, height: 32),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'EduBridge · وزارة/مؤسسة',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: ProfileAvatarButton(
              size: 38,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        DashboardMenu(
          actions: [
            DashboardMenuAction(
              id: 'support',
              label: 'الدعم الفني',
              icon: AppIcons.support,
              onSelected: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SupportSheet(),
              ),
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
                navigator.pushReplacementNamed('/home');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context) {
    return FutureBuilder<String?>(
      future: ApiService.getName(),
      builder: (context, snap) {
        final name = snap.data ?? 'الوزارة';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرحباً $name',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'إدارة شاملة للمؤسسات والموافقات',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        );
      },
    );
  }
}