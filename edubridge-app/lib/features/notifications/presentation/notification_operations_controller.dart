import 'package:flutter/foundation.dart';

/// Screen operation state; the session service still owns feed data and cursors.
class NotificationOperationsController extends ChangeNotifier {
  NotificationOperationsController({
    required Future<void> Function() reload,
    required Future<void> Function() loadMore,
    required Future<void> Function() markAllRead,
    required Future<void> Function() refresh,
  }) : _reload = reload, _loadMore = loadMore,
       _markAllRead = markAllRead, _refresh = refresh;

  final Future<void> Function() _reload, _loadMore, _markAllRead, _refresh;
  bool loading = true;
  bool loadingMore = false;
  bool markingAll = false;
  String? error;
  bool _disposed = false;
  int _loadGeneration = 0;

  void _notify() { if (!_disposed) notifyListeners(); }

  Future<void> reload() async {
    if (_disposed) return;
    final generation = ++_loadGeneration;
    loading = true;
    error = null;
    _notify();
    try {
      await _reload();
    } catch (_) {
      if (!_disposed && generation == _loadGeneration) {
        error = 'تعذّر تحميل الإشعارات';
      }
    } finally {
      if (!_disposed && generation == _loadGeneration) {
        loading = false;
        _notify();
      }
    }
  }

  Future<bool> loadMore() async {
    if (_disposed || loadingMore || markingAll) return false;
    loadingMore = true;
    _notify();
    try {
      await _loadMore();
      return !_disposed;
    } finally {
      if (!_disposed) { loadingMore = false; _notify(); }
    }
  }

  Future<bool> markAllRead() async {
    if (_disposed || markingAll || loadingMore) return false;
    markingAll = true;
    _notify();
    try {
      await _markAllRead();
      if (_disposed) return false;
      await _refresh();
      return !_disposed;
    } finally {
      if (!_disposed) { markingAll = false; _notify(); }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _loadGeneration++;
    super.dispose();
  }
}
