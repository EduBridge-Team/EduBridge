import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'welcome_screen.dart';
import 'children_screen.dart';
import 'lessons_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // أسماء الأدوار بالعربية — للترحيب
  static const _roleNames = {
    'parent': 'ولي أمر',
    'teacher': 'معلّم',
    'specialist': 'مختص',
    'admin': 'أدمن',
  };

  Future<void> _logout(BuildContext context) async {
    await ApiService.logout();
    if (!context.mounted) return;
    // بعد الخروج نرجع للشاشة الترحيبية
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  void _openChildren(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChildrenScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الألوان المتكيّفة مع الوضع الحالي (فاتح/ليلي)
    final c = JisrColors.of(context);

    return Scaffold(
  
      body: Column(
        children: [
          // ===== رأس متدرّج بهوية جسر: شعار + ترحيب بالاسم والدور =====
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          
                          child: Image.asset('assets/icon.png',
                              width: 36, height: 36),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'جسر التعليمي',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // زر الوضع الليلي/الفاتح
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: jisrThemeMode,
                          builder: (context, mode, _) => IconButton(
                            icon: Icon(
                              mode == ThemeMode.dark
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                              color: Colors.white,
                            ),
                            tooltip: mode == ThemeMode.dark
                                ? 'الوضع الفاتح'
                                : 'الوضع الليلي',
                            onPressed: toggleThemeMode,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          tooltip: 'خروج',
                          onPressed: () => _logout(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // الترحيب بالاسم والدور المحفوظين محلياً
                    FutureBuilder(
                      future: Future.wait(
                          [ApiService.getName(), ApiService.getRole()]),
                      builder: (context, snapshot) {
                        final name = snapshot.data?[0];
                        final role = _roleNames[snapshot.data?[1]];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'مرحباً بك 👋',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.white70),
                            ),
                            Text(
                              [
                                if (name != null && name.isNotEmpty) name,
                                if (role != null) '— $role',
                              ].join(' '),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
          ),

          // ===== بطاقات التنقّل =====
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MenuTile(
                  icon: '👧',
                  tint: c.tintTeal,
                  title: 'الأطفال',
                  subtitle: 'عرض الأطفال ودروسهم وتقدّمهم',
                  onTap: () => _openChildren(context),
                ),
                _MenuTile(
                  icon: '📚',
                  tint: c.tintGreen,
                  title: 'تصفح الدروس',
                  subtitle: 'كل الدروس مع بحث وقراءة صوتية',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LessonsScreen()),
                    );
                  },
                ),
                _MenuTile(
                  icon: '📊',
                  tint: c.tintOrange,
                  title: 'التقدّم والمكافآت',
                  subtitle: 'ملخّص الإنجاز والنجوم وشارات كل طفل',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const ChildrenScreen(forProgress: true)),
                    );
                  },
                ),

                const SizedBox(height: 8),
                // بطاقة تذكير بميزة القراءة الصوتية
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.tintYellow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Text('🔊', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'كل درس يُقرأ صوتياً بالعربية — اضغط «استمع» داخل الدرس',
                          style: TextStyle(fontSize: 14.5, color: c.onTint),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة تنقّل: أيقونة ملوّنة + عنوان + وصف
class _MenuTile extends StatelessWidget {
  final String icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13.5, color: c.muted),
                    ),
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