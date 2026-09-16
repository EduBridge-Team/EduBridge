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
              // ===== الشعار + زر الوضع الليلي =====
              Row(
                children: [
                  Image.asset(
                    'assets/brand_logo.png',
                    width: 164,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: jisrThemeMode,
                    builder: (context, mode, _) => Container(
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.line),
                      ),
                      child: IconButton(
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
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== بطاقة الهوية الرئيسية =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: .2),
                      blurRadius: 34,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .2),
                                  ),
                                ),
                                child: const Text(
                                  'معاً، نحو تعليم أكثر شمولاً',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'تعليم ذكي وشامل\nلكل طفل',
                                style: TextStyle(
                                  fontSize: 31,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.22,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 82,
                          height: 82,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .94),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Image.asset('assets/brand_icon.png'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'أدوات تعليمية مرنة تربط الطفل بأسرته ومعلميه ومختصيه في تجربة واحدة آمنة.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFFE4F6FF),
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroPill(
                          icon: Icons.accessibility_new,
                          label: 'متاح للجميع',
                        ),
                        _HeroPill(
                          icon: Icons.auto_awesome,
                          label: 'تعلّم مخصّص',
                        ),
                        _HeroPill(
                          icon: Icons.shield_outlined,
                          label: 'بيئة آمنة',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // زرّا الدخول وإنشاء الحساب
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _openLogin(context),
                  child: const Text('ابدأ رحلتك الآن  ←',
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
                  _StatCard(
                    emoji: '💙',
                    value: '٩٨٪',
                    label: 'رضا المتعلمين',
                    tint: c.tintTeal,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    emoji: '🎓',
                    value: '+٥٠٠٠',
                    label: 'طالب مُمكَّن',
                    tint: c.tintGreen,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    emoji: '🤝',
                    value: '١٢٠',
                    label: 'شريك تعليمي',
                    tint: c.tintOrange,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ===== الرؤية =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: .16),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
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

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
