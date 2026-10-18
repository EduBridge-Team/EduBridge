part of 'voice_command_service.dart';

extension _VoiceCommandGameNavigation on VoiceCommandService {
  Future<void> _openChildGame(String text, NavigatorState nav, {
    required int userId, String? gameId,
  }) async {
    if (_choosingGame) return;
    _choosingGame = true;
    try {
      await _ensureChildrenLoaded();
      if (await ApiService.getUserId() != userId || !nav.mounted) return;
      final players = _childrenCache.map(GamePlayer.fromChild).whereType<GamePlayer>().toList();
      final named = _findChild(text);
      GamePlayer? player = named == null ? null : GamePlayer.fromChild(named);
      if (named != null && player == null) {
        await _reply('تعذّر تحميل بيانات الطفل اللازمة للعبة');
        return;
      }
      if (player == null) {
        if (players.isEmpty) {
          await _reply('لا توجد بيانات أطفال متاحة لفتح اللعبة');
          return;
        }
        player = await showDialog<GamePlayer>(context: nav.context, builder: (context) =>
          SimpleDialog(title: const Text('اختر الطفل للعب'), children: players.map((child) =>
            SimpleDialogOption(onPressed: () => Navigator.pop(context, child),
              child: Text(child.name))).toList()));
      }
      if (player == null || await ApiService.getUserId() != userId || !nav.mounted) return;
      final selected = player;
      await _reply(gameId == null ? 'سأفتح ألعاب ${selected.name}'
        : 'سأفتح ${_gameDisplayName(gameId)} لـ ${selected.name}');
      if (await ApiService.getUserId() != userId || !nav.mounted) return;
      if (gameId != null) {
        await GameLauncher.instance.open(nav.context, gameId: gameId, player: selected);
      } else {
        await nav.push(MaterialPageRoute(builder: (_) => EducationalGamesScreen(
          childId: selected.childId, childName: selected.name, age: selected.age)));
      }
    } finally {
      _choosingGame = false;
    }
  }
}
