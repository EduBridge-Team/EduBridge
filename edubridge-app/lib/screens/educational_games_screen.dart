// شاشة الألعاب التعليمية — تتكيّف حسب البروفايل والعمر
import 'package:flutter/material.dart';
import '../games/audio_matching_game.dart';
import '../games/colors_game.dart';
import '../games/matching_game.dart';
import '../games/math_race_game.dart';
import '../games/numbers_game.dart';
import '../games/quick_action_game.dart';
import '../games/rhythm_game.dart';
import '../games/sequence_game.dart';
import '../games/shapes_game.dart';
import '../games/sign_language_game.dart';
import '../games/story_sequencer_game.dart';
import '../games/symbols_game.dart';
import '../games/visual_words_game.dart';
import '../games/word_builder_game.dart';
import '../services/accessibility_service.dart';
import '../services/encouragement_service.dart';
import '../theme.dart';
import '../utils/game_catalog.dart';

class EducationalGamesScreen extends StatelessWidget {
  final String childName;
  final int age;

  const EducationalGamesScreen({
    super.key,
    required this.childName,
    this.age = 8,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final profile = AccessibilityService.instance.profile.value;
    final group = ageGroupOf(age);

    final isBlind = profile.type == DisabilityType.blind;
    final isDeaf = profile.type == DisabilityType.deaf;
    final isCalm = profile.sensoryCalmMode;

    // تشجيع صوتي
    if (!isDeaf && !isCalm) {
      EncouragementService.instance.praiseGame();
    }

    // ✅ فلترة الألعاب حسب العمر + الإعاقة
    final games = gamesFor(profile.type, group);

    return Scaffold(
      appBar: JisrAppBar(title: 'الألعاب التعليمية 🎮'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ترحيب
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: isCalm
                    ? const LinearGradient(colors: [AppColors.teal, AppColors.tealDeep])
                    : AppColors.headerGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    isBlind ? '🎧' : isDeaf ? '🤟' : '🎉',
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
                          '${games.length} ألعاب مناسبة لعمرك (${ageGroupLabel(group)})',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // الألعاب
            ...games.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GameCard(
                    game: g,
                    onTap: () => _openGame(context, g, profile),
                  ),
                )),

            if (games.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.extension_off, size: 72, color: c.muted),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد ألعاب مناسبة بعد',
                      style: TextStyle(fontSize: 18, color: c.muted),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openGame(BuildContext context, GameInfo game, AccessibilityProfile profile) {
    Widget? screen;

    switch (game.id) {
      case 'animal_sounds':
      case 'audio_matching':
        screen = AudioMatchingGame(childName: childName);
        break;
      case 'matching':
        screen = MatchingGame(childName: childName);
        break;
      case 'shapes':
        screen = ShapesGame(childName: childName, age: age);
        break;
      case 'colors_simple':
        screen = ColorsGame(childName: childName);
        break;
      case 'colors_symbols':
        screen = SymbolsGame(childName: childName);
        break;
      case 'numbers_count':
        screen = NumbersGame(childName: childName);
        break;
      case 'numbers_math':
        screen = MathRaceGame(childName: childName, age: age);
        break;
      case 'visual_words':
        screen = VisualWordsGame(childName: childName);
        break;
      case 'word_builder':
        screen = WordBuilderGame(childName: childName, age: age);
        break;
      case 'sequence_simple':
        screen = SequenceGame(childName: childName);
        break;
      case 'story_sequencer':
        screen = StorySequencerGame(childName: childName, age: age);
        break;
      case 'sign_language':
        screen = SignLanguageGame(childName: childName);
        break;
      case 'quick_action':
        screen = QuickActionGame(childName: childName);
        break;
      case 'rhythm':
        screen = RhythmGame(childName: childName);
        break;
      // 'logic_puzzle' — يمكن إضافتها لاحقاً
    }

    if (screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen!),
      );
    }
  }
}

class _GameCard extends StatelessWidget {
  final GameInfo game;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final large = AccessibilityService.instance.profile.value.extraLargeTouchTargets;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(large ? 20 : 16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: large ? 80 : 64,
              height: large ? 80 : 64,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(game.emoji,
                  style: TextStyle(fontSize: large ? 42 : 34)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: TextStyle(
                      fontSize: large ? 20 : 17,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.description,
                    style: TextStyle(fontSize: large ? 15 : 13, color: c.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: AppColors.teal, size: 32),
          ],
        ),
      ),
    );
  }
}