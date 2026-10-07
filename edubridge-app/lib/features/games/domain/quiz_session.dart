import 'quiz_question.dart';

/// One scored answer per round; transitions are explicit and widget-independent.
class QuizSession {
  QuizSession(List<QuizQuestion> questions)
      : questions = List.unmodifiable(questions) {
    if (questions.isEmpty) throw ArgumentError('A session requires questions');
  }

  final List<QuizQuestion> questions;
  int _index = 0;
  int _score = 0;
  bool _answered = false;

  QuizQuestion get current => questions[_index];
  int get roundNumber => _index + 1;
  int get totalRounds => questions.length;
  int get correctAnswers => _score;
  int get scorePercent => (_score * 100 / totalRounds).round();
  bool get answered => _answered;
  bool get finished => _answered && roundNumber == totalRounds;

  /// Null means a duplicate or unavailable answer, without changing the score.
  bool? answer(int choice) {
    if (_answered || choice < 0 || choice >= current.choices.length) return null;
    _answered = true;
    final correct = current.isCorrect(choice);
    if (correct) _score++;
    return correct;
  }

  bool next() {
    if (!_answered || finished) return false;
    _index++;
    _answered = false;
    return true;
  }
}
