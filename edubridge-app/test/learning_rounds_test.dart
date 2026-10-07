import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/games/learning_rounds.dart';

void main() {
  LearningRounds session({int rounds = 6}) => LearningRounds(
    itemCount: 6, totalRounds: rounds, optionCount: 3, random: Random(7));

  test('each item is practiced before any target repeats', () {
    final game = session();
    final seen = <int>{};
    for (var i = 0; i < 6; i++) {
      expect(seen.add(game.target), isTrue);
      expect(game.options.toSet().length, 3);
      expect(game.options, contains(game.target));
      expect(game.choose(game.target), isTrue);
      if (i < 5) expect(game.next(), isTrue);
    }
    expect(game.finished, isTrue);
    expect(game.scorePercent, 100);
    expect(game.next(), isFalse);
    expect(game.choose(game.target), isNull);
  });

  test('rapid correct taps award and complete a round only once', () {
    final game = session();
    expect(game.choose(game.target), isTrue);
    expect(game.choose(game.target), isNull);
    expect(game.completed, 1);
    expect(game.firstTryCorrect, 1);
  });

  test('retry and hint allow learning but do not inflate first-try score', () {
    final game = session(rounds: 3);
    final wrong = game.options.firstWhere((i) => i != game.target);
    expect(game.choose(wrong), isFalse);
    expect(game.choose(wrong), isNull);
    expect(game.next(), isFalse);
    expect(game.choose(game.target), isTrue);
    expect(game.firstTryCorrect, 0);
    expect(game.next(), isTrue);
    expect(game.tried, isEmpty);
    game.hint();
    expect(game.choose(game.target), isTrue);
    expect(game.firstTryCorrect, 0);
    expect(game.next(), isTrue);
    expect(game.hinted, isFalse);
    expect(game.choose(game.target), isTrue);
    expect(game.scorePercent, 33);
  });

  test('targets do not repeat at a deck boundary', () {
    final game = session(rounds: 8);
    int? previous;
    for (var i = 0; i < 8; i++) {
      expect(game.target, isNot(previous));
      previous = game.target;
      game.choose(game.target);
      game.next();
    }
  });

  test('invalid and unavailable choices do not change progress', () {
    expect(() => LearningRounds(itemCount: 2, totalRounds: 1, optionCount: 3), throwsArgumentError);
    final game = session();
    expect(game.choose(-1), isNull);
    expect(game.completed, 0);
    expect(game.tried, isEmpty);
  });
}
