import 'dart:math';

enum ArithmeticOperation {
  addition('+'), subtraction('-'), multiplication('×');
  const ArithmeticOperation(this.symbol);
  final String symbol;
}

class ArithmeticQuestion {
  const ArithmeticQuestion(this.first, this.second, this.operation);
  final int first;
  final int second;
  final ArithmeticOperation operation;

  String get id => '$first:${operation.symbol}:$second';
  String get expression => '$first ${operation.symbol} $second = ?';
  int get answer => switch (operation) {
    ArithmeticOperation.addition => first + second,
    ArithmeticOperation.subtraction => first - second,
    ArithmeticOperation.multiplication => first * second,
  };

  List<int> choices(Random random) {
    final options = <int>{answer};
    while (options.length < 4) {
      final candidate = answer + random.nextInt(10) - 5;
      if (candidate > 0 && candidate != answer) options.add(candidate);
    }
    return List.unmodifiable(options.toList()..shuffle(random));
  }
}
