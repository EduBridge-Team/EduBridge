import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/features/games/domain/matching_board.dart';
import 'package:edubridge_app/features/games/domain/ordered_round.dart';
import 'package:edubridge_app/features/games/domain/rhythm_session.dart';

void main() {
  test('matching resolves each pair once and preserves score/streak rules', () {
    final board = MatchingBoard(['a', 'b', 'a', 'b']);
    expect(board.flip(0), isFalse);
    expect(board.flip(0), isFalse);
    expect(board.attempts, 0);
    expect(board.flip(1), isTrue);
    expect(board.flip(2), isFalse);
    expect(board.resolve(), isFalse);
    expect(board.resolve(), isNull);
    expect(board.mistakes, 1);
    expect(board.cards[0].flipped, isFalse);
    board.release();
    board.flip(0); board.flip(2);
    expect(board.resolve(), isTrue);
    expect(board.matches, 1);
    expect(board.cards[0].matched, isTrue);
    board.release();
    expect(board.flip(0), isFalse);
    board.flip(1); board.flip(3); board.resolve(); board.release();
    expect(board.finished, isTrue);
    expect(board.streak, 2);
    expect(board.attempts, 3);
    expect(board.scorePercent, 67);
    expect(() => board.cards.add(const MatchingCard(emoji: 'x')), throwsUnsupportedError);
    final replay = MatchingBoard(['x', 'y', 'x', 'y']);
    expect(replay.attempts, 0);
    expect(replay.matches, 0);
    expect(replay.locked, isFalse);
  });

  test('ordered letters preserve repeated letters and allow an incorrect retry', () {
    final round = OrderedRound('مدرسة'.split(''), random: Random(7));
    expect(round.choices.join(), isNot('مدرسة'));
    for (var i = round.choices.length - 1; i >= 0; i--) { round.selectIndex(i); }
    expect(round.complete, isTrue);
    expect(round.selectIndex(0), isFalse);
    round.reset();
    expect(round.selected, isEmpty);
    for (final letter in round.correctOrder) { expect(round.selectValue(letter), isTrue); }
    expect(round.correct, isTrue);
    final repeated = OrderedRound('ماما'.split(''), random: Random(2));
    for (final letter in repeated.correctOrder) { expect(repeated.selectValue(letter), isTrue); }
    expect(repeated.usedIndices.length, 4);
    expect(repeated.correct, isTrue);
    expect(repeated.selectValue('م'), isFalse);
  });

  test('ordered cards and single-value content terminate and remain immutable', () {
    final round = OrderedRound(['🌱', '🌿', '🌳'], random: Random(2));
    expect(round.selectIndex(-1), isFalse);
    expect(round.selectValue('missing'), isFalse);
    for (final card in round.correctOrder) { round.selectValue(card); }
    expect(round.correct, isTrue);
    expect(() => round.selected.clear(), throwsUnsupportedError);
    expect(OrderedRound(['a', 'a']).choices, ['a', 'a']);
    expect(() => OrderedRound<String>([]), throwsArgumentError);
  });

  test('rhythm pause/resume and restart keep progress and taps scoped to session', () {
    final session = RhythmSession()..start(['بيت', 'شمس']);
    session.tap(); session.tap();
    expect(session.tapCount, 2);
    session.pause(); session.tap(); session.advance();
    expect(session.index, 0);
    expect(session.tapCount, 2);
    session.resume(); session.advance();
    expect(session.currentWord, 'شمس');
    expect(session.tapCount, 0);
    session.advance();
    expect(session.complete, isTrue);
    session.finish();
    expect(session.playing, isFalse);
    session.start(['قمر']);
    expect(session.index, 0);
    expect(session.paused, isFalse);
    expect(session.currentWord, 'قمر');
  });
}
