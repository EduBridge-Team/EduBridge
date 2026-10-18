// lib/screens/educational_games_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/accessibility_service.dart';
import '../features/games/application/game_launcher.dart';
import '../features/games/domain/game_player.dart';
import '../widgets/accessibility/child_adaptation_scope.dart';
import '../services/encouragement_service.dart';
import '../theme.dart';
import '../utils/game_catalog.dart';

class EducationalGamesScreen extends StatelessWidget {
  final String childName;
  final int age;
  final int? childId;
  final EncouragementService? encouragement;

  const EducationalGamesScreen({
    super.key,
    required this.childName,
    this.age = 8,
    this.childId,
    this.encouragement,
  });

  @override
  Widget build(BuildContext context) => childId == null
      ? _buildEntry(context)
      : ChildAdaptationScope(childId: childId!, builder: _buildEntry);

  Widget _buildEntry(BuildContext context) => _GameCatalogEntry(
    encouragement: encouragement ?? EncouragementService.instance,
    child: _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    final c = JisrColors.of(context);
    final profile = AccessibilityService.instance.profile.value;
    final group = ageGroupOf(age);

    final isBlind = profile.type == DisabilityType.blind;
    final isDeaf = profile.type == DisabilityType.deaf;
    final isCalm = profile.sensoryCalmMode;

    final games = gamesFor(profile.type, group);

    return Scaffold(
      appBar: JisrAppBar(title: 'الألعاب التعليمية'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: isCalm
                    ? const LinearGradient(
                        colors: [AppColors.brandTeal, AppColors.brandBlue])
                    : AppColors.headerGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    isBlind
                        ? AppIcons.deaf
                        : isDeaf
                            ? AppIcons.signLanguage
                            : AppIcons.game,
                    color: Colors.white,
                    size: 44,
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
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ...games.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GameCard(
                    game: g,
                    onTap: () => _openGame(context, g),
                  ),
                )),

            if (games.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(AppIcons.game, size: 72, color: c.muted),
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

  Future<void> _openGame(BuildContext context, GameInfo game) async {
    await GameLauncher.instance.open(context, gameId: game.id,
      player: GamePlayer(childId: childId, name: childName, age: age));
  }

}

class _GameCard extends StatelessWidget {
  final GameInfo game;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final large =
        AccessibilityService.instance.profile.value.extraLargeTouchTargets;

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
              color: AppColors.brandBlue.withValues(alpha: 0.05),
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
                color: AppColors.brandTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(
                AppIcons.game,
                size: large ? 42 : 34,
                color: AppColors.brandBlue,
              ),
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
            const Icon(Icons.chevron_left,
                color: AppColors.brandBlue, size: 32),
          ],
        ),
      ),
    );
  }
}

/// A route welcome is an event, not a side effect of rebuilding its contents.
class _GameCatalogEntry extends StatefulWidget {
  const _GameCatalogEntry({required this.encouragement, required this.child});
  final EncouragementService encouragement;
  final Widget child;

  @override
  State<_GameCatalogEntry> createState() => _GameCatalogEntryState();
}

class _GameCatalogEntryState extends State<_GameCatalogEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent != false) {
        widget.encouragement.praiseGame();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
