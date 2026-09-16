import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/dashboard_menu.dart';
import '../widgets/legal_links_button.dart';
import 'chats_screen.dart';
import 'children_screen.dart';
import 'lessons_screen.dart';
import 'verify_identity_screen.dart';
import 'welcome_screen.dart';

class InstitutionScreen extends StatelessWidget {
  const InstitutionScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await ApiService.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Image.asset('assets/brand_icon.png'),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'لوحة المؤسسة التعليمية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        DashboardMenu(
                          actions: [
                            DashboardMenuAction(
                              id: 'theme',
                              label: 'تبديل وضع العرض',
                              icon: Icons.contrast,
                              onSelected: toggleThemeMode,
                            ),
                            DashboardMenuAction(
                              id: 'legal',
                              label: 'الخصوصية والحساب',
                              icon: Icons.privacy_tip_outlined,
                              onSelected: () =>
                                  const LegalLinksButton().show(context),
                            ),
                            DashboardMenuAction(
                              id: 'logout',
                              label: 'تسجيل الخروج',
                              icon: Icons.logout,
                              destructive: true,
                              onSelected: () => _logout(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    FutureBuilder<String?>(
                      future: ApiService.getName(),
                      builder: (context, snapshot) => Text(
                        'أهلاً، ${snapshot.data?.isNotEmpty == true ? snapshot.data : 'فريق المؤسسة'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'أدر الفريق وتابع الحالات والمحتوى من مساحة واحدة.',
                      style: TextStyle(color: Color(0xFFDDF7FF), fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.groups_2_outlined,
                        value: '٢٤',
                        label: 'عضوًا بالفريق',
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.fact_check_outlined,
                        value: '١٨',
                        label: 'حالة نشطة',
                        color: AppColors.tealDeep,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'مهام المؤسسة',
                  style: TextStyle(
                    color: c.heading,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: Icons.badge_outlined,
                  title: 'ملفات الطلاب',
                  subtitle: 'عرض الطلاب والحالات المرتبطة بالمؤسسة',
                  color: AppColors.navy,
                  onTap: () => _open(context, const ChildrenScreen()),
                ),
                _ActionCard(
                  icon: Icons.menu_book_rounded,
                  title: 'مكتبة الدروس',
                  subtitle: 'الوصول إلى المحتوى التعليمي المعتمد',
                  color: AppColors.tealDeep,
                  onTap: () => _open(context, const LessonsScreen()),
                ),
                _ActionCard(
                  icon: Icons.forum_outlined,
                  title: 'تواصل الفريق',
                  subtitle: 'محادثات المعلمين والمختصين',
                  color: const Color(0xFF7557BD),
                  onTap: () => _open(context, const ChatsScreen()),
                ),
                _ActionCard(
                  icon: Icons.verified_user_outlined,
                  title: 'توثيق المؤسسة',
                  subtitle: 'متابعة حالة الهوية والصلاحيات',
                  color: const Color(0xFFB77318),
                  onTap: () => _open(context, const VerifyIdentityScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: c.heading,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: TextStyle(color: c.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: c.heading,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: c.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios_new_rounded, color: c.muted, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}
