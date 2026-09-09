import 'package:edubridge_app/screens/admin_screen.dart';
import 'package:edubridge_app/screens/lessons_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'chats_screen.dart';
import 'support_sheet.dart';

class MinistryScreen extends StatelessWidget {
  const MinistryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      body: Column(
        children: [
          // الرأس
          Container(
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
                    Row(
                      children: [
                        Image.asset('assets/icon.png', width: 32, height: 32),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'جسر التعليمي - وزارة/مؤسسة',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.headset_mic, color: Colors.white),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const SupportSheet(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ChatsScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () async {
                            await ApiService.logout();
                            if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<String?>(
                      future: ApiService.getName(),
                      builder: (context, snap) {
                        final name = snap.data ?? 'الوزارة';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('مرحباً $name 👋',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('إدارة شاملة للمؤسسات التعليمية والتحقق',
                                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                          ],
                        );
                      },
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
                // بطاقات إحصائية مبدئية
                Row(
                  children: [
                    _InfoCard(icon: '🏫', value: '١٢٠', label: 'مؤسسة شريكة', tint: c.tintTeal),
                    const SizedBox(width: 10),
                    _InfoCard(icon: '👩‍🎓', value: '+٥٠٠٠', label: 'طالب مُمكَّن', tint: c.tintGreen),
                    const SizedBox(width: 10),
                    _InfoCard(icon: '🧩', value: '٣٥', label: 'برنامج تعليمي', tint: c.tintOrange),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('أدوات الإدارة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: '📚',
                  tint: c.tintTeal,
                  title: 'تصفح الدروس',
                  subtitle: 'عرض جميع الدروس المضافة',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LessonsScreen()),
                    );
                  },
                ),
                _MenuTile(
                  icon: '📊',
                  tint: c.tintOrange,
                  title: 'الإحصائيات والتقارير',
                  subtitle: 'تحليل بيانات التعليم',
                  onTap: () {
                    // يمكن إضافة شاشة تقارير لاحقاً
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('قريباً')),
                    );
                  },
                ),
                _MenuTile(
                  icon: '🔍',
                  tint: c.tintGreen,
                  title: 'البحث بالهوية',
                  subtitle: 'البحث عن طالب أو مستخدم',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchByIdentityScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color tint;

  const _InfoCard({required this.icon, required this.value, required this.label, required this.tint});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: c.heading)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.tint, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.heading)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 13.5, color: c.muted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}