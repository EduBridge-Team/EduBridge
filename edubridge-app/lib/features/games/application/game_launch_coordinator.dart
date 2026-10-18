/// Serializes preparation and the complete route lifetime across entry points.
class GameLaunchCoordinator {
  bool _busy = false;
  bool get busy => _busy;

  Future<bool> run({
    required Future<void> Function() prepare,
    required Future<bool> Function() canOpen,
    required void Function() begin,
    required Future<void> Function() open,
    required void Function() end,
  }) async {
    if (_busy) return false;
    _busy = true;
    var started = false;
    try {
      await prepare();
      if (!await canOpen()) return false;
      begin();
      started = true;
      await open();
      return true;
    } finally {
      if (started) end();
      _busy = false;
    }
  }
}
