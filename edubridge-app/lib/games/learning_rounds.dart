import 'dart:math';

/// Round state is independent of widgets so rapid taps cannot award twice.
class LearningRounds {
  LearningRounds({required this.itemCount, required this.totalRounds,
    required this.optionCount, Random? random}) : _random = random ?? Random() {
    if (itemCount < 2 || totalRounds < 1 || optionCount < 2 || optionCount > itemCount) {
      throw ArgumentError('Invalid learning round configuration');
    }
    _prepare();
  }

  final int itemCount;
  final int totalRounds;
  final int optionCount;
  final Random _random;
  final List<int> _deck = [];
  final Set<int> _tried = {};
  List<int> _options = [];
  int target = 0;
  int completed = 0;
  int firstTryCorrect = 0;
  bool answered = false;
  bool hinted = false;
  List<int> get options => List.unmodifiable(_options);
  Set<int> get tried => Set.unmodifiable(_tried);
  bool get finished => completed == totalRounds;
  int get scorePercent => (firstTryCorrect * 100 / totalRounds).round();

  void _prepare() {
    final previous = completed > 0 ? target : -1;
    if (_deck.isEmpty) {
      _deck.addAll(List.generate(itemCount, (i) => i)..shuffle(_random));
      if (_deck.last == previous) {
        final first = _deck.first;
        _deck[0] = _deck.last;
        _deck[_deck.length - 1] = first;
      }
    }
    target = _deck.removeLast();
    final distractors = List.generate(itemCount, (i) => i)
      ..remove(target)
      ..shuffle(_random);
    _options = [target, ...distractors.take(optionCount - 1)]..shuffle(_random);
    _tried.clear();
    answered = false;
    hinted = false;
  }

  /// Null means the answer is ignored (duplicate, unavailable or locked).
  bool? choose(int option) {
    if (finished || answered || !_options.contains(option) || _tried.contains(option)) return null;
    final firstTry = _tried.isEmpty && !hinted;
    _tried.add(option);
    if (option != target) return false;
    answered = true;
    completed++;
    if (firstTry) firstTryCorrect++;
    return true;
  }

  void hint() { if (!answered && !finished) hinted = true; }

  bool next() {
    if (!answered || finished) return false;
    _prepare();
    return true;
  }
}
