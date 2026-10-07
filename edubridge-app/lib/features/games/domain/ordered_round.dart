import 'dart:math';

/// Tracks positions, so two identical letters can both be used exactly once.
class OrderedRound<T> {
  OrderedRound(List<T> order, {Random? random})
      : correctOrder = List.unmodifiable(order), _choices = List<T>.from(order) {
    if (order.isEmpty) throw ArgumentError('An ordered round requires items');
    if (order.toSet().length > 1) {
      do { _choices.shuffle(random); } while (_same(_choices, correctOrder));
    }
  }
  final List<T> correctOrder;
  final List<T> _choices;
  final List<int> _selected = [];
  List<T> get choices => List.unmodifiable(_choices);
  List<T> get selected => List.unmodifiable(_selected.map((index) => _choices[index]));
  Set<int> get usedIndices => Set.unmodifiable(_selected);
  bool get complete => _selected.length == correctOrder.length;
  bool get correct => complete && _same(selected, correctOrder);

  bool selectIndex(int index) {
    if (complete || index < 0 || index >= _choices.length || _selected.contains(index)) return false;
    _selected.add(index);
    return true;
  }

  bool selectValue(T value) {
    for (var i = 0; i < _choices.length; i++) {
      if (_choices[i] == value && !_selected.contains(i)) return selectIndex(i);
    }
    return false;
  }

  void reset() => _selected.clear();

  static bool _same<T>(List<T> first, List<T> second) {
    if (first.length != second.length) return false;
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }
}
