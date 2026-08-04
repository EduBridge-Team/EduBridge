// الشاشة الرئيسية — لوحة تنقّل بهوية «جسر»
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'login_screen.dart';
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                  tint: AppColors.tintTeal,
                  title: 'الأطفال',
                  subtitle: 'عرض الأطفال ودروسهم وتقدّمهم',
                  onTap: () => _openChildren(context),
                ),
                _MenuTile(
                  icon: '📚',
                  tint: AppColors.tintGreen,
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
                  tint: AppColors.tintOrange,
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
                    color: AppColors.tintYellow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      Text('🔊', style: TextStyle(fontSize: 28)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'كل درس يُقرأ صوتياً بالعربية — اضغط «استمع» داخل الدرس',
                          style: TextStyle(
                              fontSize: 14.5, color: AppColors.ink),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 13.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
