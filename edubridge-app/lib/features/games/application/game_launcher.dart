import 'package:flutter/material.dart';
import '../../../games/game_content.dart';
import '../../../services/api_service.dart';
import '../../../services/game_progress_service.dart';
import '../../../widgets/accessibility/child_adaptation_scope.dart';
import '../domain/game_player.dart';
import 'game_launch_coordinator.dart';
import 'game_screen_factory.dart';

class GameLauncher {
  GameLauncher._();
  static final instance = GameLauncher._();
  final _coordinator = GameLaunchCoordinator();

  Future<bool> open(BuildContext context, {
    required String gameId, required GamePlayer player,
  }) async {
    final screen = GameScreenFactory.build(gameId, player);
    if (screen == null || !context.mounted) return false;
    int? owner;
    try {
      return await _coordinator.run(
        prepare: () async {
          owner = await ApiService.getUserId();
          await GameContent.instance.prepare(ownerId: owner, childId: player.childId);
          await GameProgressService.instance.flushPending();
        },
        canOpen: () async {
          if (await ApiService.getUserId() != owner) return false;
          return context.mounted && ModalRoute.of(context)?.isCurrent != false;
        },
        begin: () => GameProgressService.instance.begin(
          childId: player.childId, gameKey: GameScreenFactory.canonicalId(gameId)),
        open: () async {
          await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) =>
            player.childId == null ? screen : ChildAdaptationScope(
              childId: player.childId!, builder: (_) => screen)));
        },
        end: GameProgressService.instance.end,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('تعذّر فتح اللعبة، حاول مرة أخرى')));
      }
      return false;
    }
  }
}
