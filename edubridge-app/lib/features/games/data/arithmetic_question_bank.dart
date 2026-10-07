import '../domain/arithmetic_question.dart';

class ArithmeticQuestionBank {
  static int levelForAge(int age) => age <= 8 ? 1 : age <= 11 ? 2 : 3;

  static List<ArithmeticQuestion> forAge(int age) {
    final max = age <= 8 ? 10 : age <= 11 ? 25 : 60;
    return List.unmodifiable([
      for (var a = 1; a <= max; a++)
        for (var b = 1; b <= (age <= 8 ? 10 : 15); b++) ...[
          ArithmeticQuestion(a, b, ArithmeticOperation.addition),
          if (age > 8 && a > b)
            ArithmeticQuestion(a, b, ArithmeticOperation.subtraction),
          if (age > 11 && a <= 12 && b <= 12)
            ArithmeticQuestion(a, b, ArithmeticOperation.multiplication),
        ],
    ]);
  }
}
