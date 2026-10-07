class MatchingCard {
  const MatchingCard({required this.emoji, this.matched = false, this.flipped = false});
  final String emoji;
  final bool matched;
  final bool flipped;
  MatchingCard copyWith({bool? matched, bool? flipped}) => MatchingCard(
    emoji: emoji, matched: matched ?? this.matched, flipped: flipped ?? this.flipped);
}

class MatchingBoard {
  MatchingBoard(List<String> deck)
      : _cards = deck.map((emoji) => MatchingCard(emoji: emoji)).toList();
  final List<MatchingCard> _cards;
  int? _first, _second;
  bool _resolved = false;
  int _matches = 0;
  int get matches => _matches;
  int _attempts = 0;
  int get attempts => _attempts;
  int _mistakes = 0;
  int get mistakes => _mistakes;
  int _streak = 0;
  int get streak => _streak;
  List<MatchingCard> get cards => List.unmodifiable(_cards);
  bool get locked => _second != null;
  bool get finished => _matches == _cards.length ~/ 2;
  int get scorePercent => _attempts == 0 ? 0
    : ((_cards.length ~/ 2) * 100 / _attempts).round().clamp(0, 100).toInt();

  /// True when two different eligible cards are ready for delayed resolution.
  bool flip(int index) {
    if (locked || index < 0 || index >= _cards.length ||
        _cards[index].flipped || _cards[index].matched) return false;
    _cards[index] = _cards[index].copyWith(flipped: true);
    if (_first == null) { _first = index; return false; }
    _second = index;
    _attempts++;
    return true;
  }

  bool? resolve() {
    if (!locked || _resolved) return null;
    _resolved = true;
    final first = _cards[_first!], second = _cards[_second!];
    final matched = first.emoji == second.emoji;
    _cards[_first!] = first.copyWith(matched: matched, flipped: matched);
    _cards[_second!] = second.copyWith(matched: matched, flipped: matched);
    if (matched) { _matches++; _streak++; }
    else { _mistakes++; _streak = 0; }
    return matched;
  }

  void release() {
    if (!_resolved) return;
    _first = null; _second = null; _resolved = false;
  }
}
