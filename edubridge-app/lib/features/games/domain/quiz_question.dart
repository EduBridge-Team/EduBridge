import 'dart:math';

/// A question's answer identity is independent of its presentation order.
class QuizQuestion {
  QuizQuestion({
    required this.prompt,
    required List<String> choices,
    required this.correctAnswerIndex,
    this.passage,
  }) : choices = List.unmodifiable(choices) {
    if (choices.length < 2 || correctAnswerIndex < 0 ||
        correctAnswerIndex >= choices.length) {
      throw ArgumentError('A question requires choices and a valid answer');
    }
  }

  final String prompt;
  final String? passage;
  final List<String> choices;
  final int correctAnswerIndex;

  bool isCorrect(int index) => index == correctAnswerIndex;

  QuizQuestion shuffled({Random? random}) {
    final order = List.generate(choices.length, (index) => index)..shuffle(random);
    return QuizQuestion(
      prompt: prompt,
      passage: passage,
      choices: order.map((index) => choices[index]).toList(),
      correctAnswerIndex: order.indexOf(correctAnswerIndex),
    );
  }
}
