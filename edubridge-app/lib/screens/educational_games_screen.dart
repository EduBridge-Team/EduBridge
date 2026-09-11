// شاشة الألعاب التعليمية — تتكيّف تلقائياً حسب بروفايل الطفل
import 'package:flutter/material.dart';
import '../games/audio_matching_game.dart';
import '../games/colors_game.dart';
import '../games/matching_game.dart';
import '../games/numbers_game.dart';
import '../games/sign_language_game.dart';
import '../services/accessibility_service.dart';
import '../services/encouragement_service.dart';
import '../theme.dart';

class EducationalGamesScreen extends StatelessWidget {
  final String childName;

  const EducationalGamesScreen({super.key, required this.childName});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final profile = AccessibilityService.instance.profile.value;

    final isBlind = profile.type == DisabilityType.blind;
    final isDeaf = profile.type == DisabilityType.deaf;
    final isCalm = profile.sensoryCalmMode;

    // ✅ تشجيع صوتي (باستثناء الأصمّ والتوحّد الشديد)
    if (!isDeaf && !isCalm) {
      EncouragementService.instance.praiseGame();
    }

    return Scaffold(
      appBar: JisrAppBar(title: 'الألعاب التعليمية 🎮'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── ترحيب ───
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: isCalm
                    ? const LinearGradient(
                        colors: [AppColors.teal, AppColors.tealDeep])
                    : AppColors.headerGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    isBlind
                        ? '🎧'
                        : isDeaf
                            ? '🤟'
                            : '🎉',
                    style: const TextStyle(fontSize: 44),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBlind
                              ? 'ألعاب سمعية!'
                              : isDeaf
                                  ? 'مرحباً يا بطل!'
                                  : 'وقت المرح!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBlind
                              ? 'ألعاب يمكنك لعبها بأذنيك يا $childName'
                              : isDeaf
                                  ? 'ألعاب بصرية ممتعة لك يا $childName'
                                  : 'هيا نلعب ونتعلم معاً يا $childName',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── للأعمى: لعبة الأصوات ───
            if (isBlind) ...[
              _GameCard(
                title: 'لعبة الأصوات',
                description: 'استمع وطابق البطاقات',
                emoji: '🎧',
                color: AppColors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AudioMatchingGame(childName: childName),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ─── للأصمّ: لعبة لغة الإشارة ───
            if (isDeaf) ...[
              _GameCard(
                title: 'لعبة لغة الإشارة',
                description: 'تعلّم الحروف بإشارات اليد 🤟',
                emoji: '🤟',
                color: AppColors.pink,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SignLanguageGame(childName: childName),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ─── الألعاب العامة (لكل من ليس أعمى) ───
            if (!isBlind) ...[
              _GameCard(
                title: 'لعبة المطابقة',
                description: 'اعثر على البطاقات المتشابهة',
                emoji: '🎴',
                color: AppColors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchingGame(childName: childName),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _GameCard(
                title: 'لعبة الألوان',
                description: 'اختر اللون الصحيح',
                emoji: '🎨',
                color: AppColors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ColorsGame(childName: childName),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _GameCard(
                title: 'لعبة الأرقام',
                description: 'اعدّ واختر الرقم الصحيح',
                emoji: '🔢',
                color: AppColors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NumbersGame(childName: childName),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final profile = AccessibilityService.instance.profile.value;
    final largeTargets = profile.extraLargeTouchTargets;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(largeTargets ? 24 : 20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.line, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: largeTargets ? 88 : 70,
              height: largeTargets ? 88 : 70,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: TextStyle(fontSize: largeTargets ? 48 : 38),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: largeTargets ? 22 : 19,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: largeTargets ? 16 : 14,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: color, size: 32),
          ],
        ),
      ),
    );
  }
}