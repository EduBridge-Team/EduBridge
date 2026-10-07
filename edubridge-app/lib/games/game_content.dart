import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// A least-recently-used shuffle bag, shared across replays and app restarts.
/// History is local and scoped to the signed-in account and selected child.
class GameContent {
  GameContent({Random? random}) : _random = random ?? Random();
  static final instance = GameContent();
  final Random _random;
  final Map<String, List<String>> _history = {};
  SharedPreferences? _prefs;
  String _scope = 'guest';
  Future<void> _writes = Future<void>.value();

  Future<void> prepare({required int? ownerId, required int? childId}) async {
    await _writes;
    _scope = '${ownerId ?? 0}_${childId ?? 0}';
    _history.clear();
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null; // Games still vary when local storage is unavailable.
    }
  }

  T pick<T>(String bank, List<T> items, String Function(T) id) {
    if (items.isEmpty) throw ArgumentError('Content bank must not be empty');
    final key = 'game_content_v1_${_scope}_$bank';
    final history = _history.putIfAbsent(key,
        () => List<String>.from(_prefs?.getStringList(key) ?? const []));
    final candidates = List<T>.from(items)..shuffle(_random);
    var chosen = candidates.first;
    var oldest = history.length;
    for (final item in candidates) {
      final position = history.indexOf(id(item));
      if (position < oldest) {
        chosen = item;
        oldest = position;
      }
      if (position == -1) break;
    }
    history.remove(id(chosen));
    history.add(id(chosen));
    // Retain enough history for the largest generated bank, but bound storage.
    if (history.length > 512) history.removeRange(0, history.length - 512);
    final snapshot = List<String>.from(history);
    final prefs = _prefs;
    _writes = _writes.then((_) async {
      if (prefs != null) await prefs.setStringList(key, snapshot);
    }).catchError((Object _) {});
    return chosen;
  }

  List<T> take<T>(String bank, List<T> items, int count, String Function(T) id) {
    final remaining = List<T>.from(items);
    final result = <T>[];
    while (result.length < count && remaining.isNotEmpty) {
      final item = pick(bank, remaining, id);
      result.add(item);
      remaining.removeWhere((candidate) => id(candidate) == id(item));
    }
    return result;
  }

  Future<void> get settled => _writes;
}
