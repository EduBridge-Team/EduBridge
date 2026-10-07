import 'dart:math';
import '../../../games/game_content.dart';
import '../data/arithmetic_question_bank.dart';
import '../data/learning_question_bank.dart';
import '../domain/arithmetic_question.dart';
import '../domain/quiz_question.dart';
import '../domain/quiz_session.dart';

/// Connects local history to pure domain models; screens only request a session.
class GameQuestionFactory {
  GameQuestionFactory({GameContent? content, Random? random})
      : _content = content ?? GameContent.instance,
        _random = random ?? Random();

  final GameContent _content;
  final Random _random;

  QuizSession logic() => _quiz('logic', LearningQuestionBank.logic, 5);
  QuizSession reading() => _quiz('reading', LearningQuestionBank.reading, 3);

  QuizSession _quiz(String key, List<QuizQuestion> bank, int count) => QuizSession(
    _content.take(key, bank, count, (question) => question.prompt)
      .map((question) => question.shuffled(random: _random)).toList(),
  );

  ArithmeticQuestion arithmetic(int age) => _content.pick(
    'math_${ArithmeticQuestionBank.levelForAge(age)}',
    ArithmeticQuestionBank.forAge(age),
    (question) => question.id,
  );

  List<int> arithmeticChoices(ArithmeticQuestion question) => question.choices(_random);
}
