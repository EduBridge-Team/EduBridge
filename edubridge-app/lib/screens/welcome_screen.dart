// الشاشة الترحيبية — تظهر قبل تسجيل الدخول (للضيوف)
// تعريف بالمنصة بهوية «جسر»: رسالة، إحصاءات، رؤية، ومسارات تعليمية
// الفكرة والبنية من تصميم الفريق، منفّذة بنظام ألوان الهوية المتكيّف
import 'package:flutter/material.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _openLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== الشعار واسم المنصة + زر الوضع الليلي =====
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.line),
                    ),
                    child: Image.asset('assets/icon.png', width: 38, height: 38),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'جسر التعليمي',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: jisrThemeMode,
                    builder: (context, mode, _) => IconButton(
                      icon: Icon(
                        mode == ThemeMode.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: c.heading,
                      ),
                      tooltip: mode == ThemeMode.dark
                          ? 'الوضع الفاتح'
                          : 'الوضع الليلي',
                      onPressed: toggleThemeMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ===== الترحيب =====
              Text(
                'نبني جسوراً نحو مستقبلٍ شاملٍ للجميع',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'نؤمن بأن التعليم حقّ للجميع — محتوى تعليمي متاح وميسّر '
                'لكل طفل، بغضّ النظر عن قدراته الجسدية أو العقلية.',
                style: TextStyle(fontSize: 15.5, color: c.muted, height: 1.8),
              ),
              const SizedBox(height: 20),

              // زرّا الدخول وإنشاء الحساب
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _openLogin(context),
                  child: const Text('🚀 ابدأ رحلتك التعليمية',
                      style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _openRegister(context),
                  child: const Text('إنشاء حساب جديد',
                      style: TextStyle(fontSize: 17)),
                ),
              ),
              const SizedBox(height: 24),

              // ===== الإحصاءات =====
              Row(
                children: [
                  _StatCard(emoji: '💙', value: '٩٨٪', label: 'رضا المتعلمين', tint: c.tintTeal),
                  const SizedBox(width: 10),
                  _StatCard(emoji: '🎓', value: '+٥٠٠٠', label: 'طالب مُمكَّن', tint: c.tintGreen),
                  const SizedBox(width: 10),
                  _StatCard(emoji: '🤝', value: '١٢٠', label: 'شريك تعليمي', tint: c.tintOrange),
                ],
              ),
              const SizedBox(height: 20),

              // ===== الرؤية =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👁️ رؤية بلا حدود',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    SizedBox(height: 8),
                    Text(
                      'نسعى لأن نكون المرجع الأول في الوطن العربي للتعليم '
                      'الرقمي المتاح، حيث تذوب الفوارق الجسدية وتبرز القدرات '
                      'العقلية والإبداعية.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ===== المزايا =====
              _FeatureCard(
                emoji: '🤝',
                tint: c.tintTeal,
                title: 'الدعم المستمر',
                desc: 'مرافقة المتعلم في كل خطوة لضمان النجاح.',
              ),
              const SizedBox(height: 10),
              _FeatureCard(
                emoji: '📚',
                tint: c.tintGreen,
                title: 'تنوع المناهج',
                desc: 'محتوى تعليمي يناسب مختلف أنواع الإعاقات.',
              ),
              const SizedBox(height: 24),

              // ===== المسارات التعليمية =====
              Text(
                'مسارات تعليمية متخصصة',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
              const SizedBox(height: 12),
              _ProgramCard(
                emoji: '🤟',
                tint: c.tintTeal,
                title: 'لغة الإشارة المتقدمة',
                desc: 'دورة شاملة لتعلم لغة الإشارة من الأساسيات وحتى الاحتراف.',
                onDiscover: () => _openLogin(context),
              ),
              const SizedBox(height: 10),
              _ProgramCard(
                emoji: '📖',
                tint: c.tintGreen,
                title: 'تقنيات القراءة الميسّرة',
                desc: 'تدريب عملي لتعزيز استقلالية القراءة والتعلم لكل طفل.',
                onDiscover: () => _openLogin(context),
              ),
              const SizedBox(height: 10),
              _ProgramCard(
                emoji: '🧩',
                tint: c.tintOrange,
                title: 'المهارات الحياتية الرقمية',
                desc: 'برنامج مخصص لتمكين الأطفال ذوي الإعاقات الإدراكية من '
                    'التعامل مع العالم الرقمي بأمان.',
                onDiscover: () => _openLogin(context),
              ),
              const SizedBox(height: 28),

              // ===== الشعار الختامي =====
              Center(
                child: Text(
                  'تعلم بلا حدود .. فرص متساوية للجميع 💙',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: c.muted,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة إحصائية صغيرة: أيقونة + رقم + وصف
class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color tint;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.tint,
  });

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
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة ميزة: أيقونة ملوّنة + عنوان + وصف
class _FeatureCard extends StatelessWidget {
  final String emoji;
  final Color tint;
  final String title;
  final String desc;

  const _FeatureCard({
    required this.emoji,
    required this.tint,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 13.5, color: c.muted, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة مسار تعليمي: أيقونة + عنوان + وصف + زر «اكتشف المسار»
class _ProgramCard extends StatelessWidget {
  final String emoji;
  final Color tint;
  final String title;
  final String desc;
  final VoidCallback onDiscover;

  const _ProgramCard({
    required this.emoji,
    required this.tint,
    required this.title,
    required this.desc,
    required this.onDiscover,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(fontSize: 14, color: c.muted, height: 1.7),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onDiscover,
              child: const Text('اكتشف المسار ‹', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
