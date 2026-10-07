import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/features/games/application/game_question_factory.dart';
import 'package:edubridge_app/features/games/data/arithmetic_question_bank.dart';
import 'package:edubridge_app/features/games/data/learning_question_bank.dart';
import 'package:edubridge_app/features/games/domain/arithmetic_question.dart';
import 'package:edubridge_app/features/games/domain/quiz_question.dart';
import 'package:edubridge_app/features/games/domain/quiz_session.dart';
import 'package:edubridge_app/games/game_content.dart';

void main() {
  test('existing banks retain their content sizes and valid answer identities', () {
    expect(LearningQuestionBank.logic.length, 105);
    expect(LearningQuestionBank.reading.length, 12);
    expect(LearningQuestionBank.logic.first.choices[
      LearningQuestionBank.logic.first.correctAnswerIndex], 'للعصفور أجنحة');
    expect(LearningQuestionBank.reading.first.passage, startsWith('ذهب سامر إلى المكتبة'));
    for (final bank in [LearningQuestionBank.logic, LearningQuestionBank.reading]) {
      expect(bank.map((question) => question.prompt).toSet().length, bank.length);
      for (final question in bank) {
        final shuffled = question.shuffled(random: Random(7));
        expect(shuffled.choices[shuffled.correctAnswerIndex],
          question.choices[question.correctAnswerIndex]);
        expect(shuffled.passage, question.passage);
        expect(shuffled.choices.toSet(), question.choices.toSet());
        expect(() => shuffled.choices.add('extra'), throwsUnsupportedError);
      }
    }
  });

  test('sessions score one answer per round and retain wrong-answer progression', () {
    final question = QuizQuestion(prompt: 'سؤال', choices: ['صحيح', 'خطأ'], correctAnswerIndex: 0);
    final session = QuizSession([question, question, question]);
    expect(session.next(), isFalse);
    expect(session.answer(-1), isNull);
    expect(session.answer(0), isTrue);
    expect(session.answer(0), isNull);
    expect(session.correctAnswers, 1);
    expect(session.next(), isTrue);
    expect(session.answer(1), isFalse);
    expect(session.answer(0), isNull);
    expect(session.next(), isTrue);
    expect(session.answer(0), isTrue);
    expect(session.finished, isTrue);
    expect(session.roundNumber, 3);
    expect(session.scorePercent, 67);
    expect(session.next(), isFalse);
  });

  test('factory keeps session lengths and history keys across replays', () {
    final content = GameContent(random: Random(2));
    final factory = GameQuestionFactory(content: content, random: Random(3));
    final first = factory.reading();
    final second = factory.reading();
    expect(first.totalRounds, 3);
    expect(factory.logic().totalRounds, 5);
    expect(first.questions.map((question) => question.prompt).toSet()
      .intersection(second.questions.map((question) => question.prompt).toSet()), isEmpty);
  });

  test('arithmetic age boundaries preserve operators, ranges and unique choices', () {
    for (final age in [7, 8, 9, 11, 12, 14]) {
      final bank = ArithmeticQuestionBank.forAge(age);
      expect(bank.map((question) => question.id).toSet().length, bank.length);
      expect(bank.every((question) => question.answer > 0), isTrue);
      final operations = bank.map((question) => question.operation).toSet();
      expect(operations, age <= 8 ? {ArithmeticOperation.addition}
        : age <= 11 ? {ArithmeticOperation.addition, ArithmeticOperation.subtraction}
        : ArithmeticOperation.values.toSet());
      expect(bank.map((question) => question.first).reduce(max), age <= 8 ? 10 : age <= 11 ? 25 : 60);
      for (final question in bank) {
        final options = question.choices(Random(5));
        expect(options.length, 4);
        expect(options.toSet().length, 4);
        expect(options, contains(question.answer));
        expect(options.every((answer) => answer > 0), isTrue);
      }
    }
  });
}
