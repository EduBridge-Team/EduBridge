import '../l10n/generated/app_localizations.dart';
import '../features/games/data/learning_question_bank.dart';
import '../features/games/domain/quiz_question.dart';

/// Presentation adapters preserve the canonical shuffled answers.
abstract final class LogicGameDisplay {
  static final _additions = {
    for (var a = 1; a <= 9; a++)
      for (var b = 1; b <= 5; b++)
        'يوجد $a أقلام، وأضفنا $b أقلام. كم أصبح العدد؟': (a, b),
  };
  static final _subtractions = {
    for (var a = 5; a <= 12; a++)
      for (var b = 1; b <= 4; b++)
        'مع سارة $a ملصقات، أعطت صديقتها $b ملصقات. كم بقي معها؟': (a, b),
  };
  static final _sequences = {
    for (var start = 1; start <= 6; start++)
      for (var step = 1; step <= 3; step++)
        'ما العدد التالي: $start، ${start + step}، ${start + step * 2}؟': (start, start + step, start + step * 2),
  };
  static QuizQuestion question(QuizQuestion original, AppLocalizations strings) {
    final addition = _additions[original.prompt];
    final subtraction = _subtractions[original.prompt];
    final sequence = _sequences[original.prompt];
    final generatedPrompt = addition != null ? strings.logicAddition(addition.$1, addition.$2)
        : subtraction != null ? strings.logicSubtraction(subtraction.$1, subtraction.$2)
        : sequence != null ? strings.logicSequence(sequence.$1, sequence.$2, sequence.$3) : null;
    if (generatedPrompt != null) {
      return QuizQuestion(prompt: generatedPrompt, choices: original.choices,
        correctAnswerIndex: original.correctAnswerIndex, passage: original.passage);
    }
    final translated = switch (original.prompt) {
      'كل الطيور لها أجنحة، والعصفور طائر. ماذا نعرف؟' => (prompt: strings.logicQuestionBird, choices: [strings.logicBirdOption0, strings.logicBirdOption1, strings.logicBirdOption2, strings.logicBirdOption3]),
      'إذا كان أحمد أطول من سامر، وسامر أطول من كريم، فمن الأطول؟' => (prompt: strings.logicQuestionHeight, choices: [strings.logicHeightOption0, strings.logicHeightOption1, strings.logicHeightOption2, strings.logicHeightOption3]),
      'يوجد 3 كتب على الطاولة وأضفنا كتابين. كم أصبح العدد؟' => (prompt: strings.logicQuestionBooks, choices: [strings.logicBooksOption0, strings.logicBooksOption1, strings.logicBooksOption2, strings.logicBooksOption3]),
      'إذا كانت كل المربعات أشكالاً، وهذا الشكل مربع، فما الصحيح؟' => (prompt: strings.logicQuestionSquare, choices: [strings.logicSquareOption0, strings.logicSquareOption1, strings.logicSquareOption2, strings.logicSquareOption3]),
      'بدأ الدرس الساعة 9 وانتهى الساعة 10. كم استغرق؟' => (prompt: strings.logicQuestionTime, choices: [strings.logicTimeOption0, strings.logicTimeOption1, strings.logicTimeOption2, strings.logicTimeOption3]),
      'ليلى أمام هدى في الصف، وهدى أمام نور. من تقف أولاً؟' => (prompt: strings.logicQuestionLine, choices: [strings.logicLineOption0, strings.logicLineOption1, strings.logicLineOption2, strings.logicLineOption3]),
      'أي شيء لا ينتمي إلى المجموعة: تفاحة، موزة، برتقالة، قلم؟' => (prompt: strings.logicQuestionGroup, choices: [strings.logicGroupOption0, strings.logicGroupOption1, strings.logicGroupOption2, strings.logicGroupOption3]),
      'كل الأسماك تعيش في الماء. السردين سمكة. أين يعيش؟' => (prompt: strings.logicQuestionFish, choices: [strings.logicFishOption0, strings.logicFishOption1, strings.logicFishOption2, strings.logicFishOption3]),
      'إذا كان اليوم الثلاثاء، فما اليوم التالي؟' => (prompt: strings.logicQuestionDay, choices: [strings.logicDayOption0, strings.logicDayOption1, strings.logicDayOption2, strings.logicDayOption3]),
      'أي شكل ليس له زوايا؟' => (prompt: strings.logicQuestionCorners, choices: [strings.logicCornersOption0, strings.logicCornersOption1, strings.logicCornersOption2, strings.logicCornersOption3]),
      _ => null,
    };
    if (translated == null) return original;
    final canonical = LearningQuestionBank.logic.firstWhere((item) => item.prompt == original.prompt);
    if (original.choices.any((choice) => !canonical.choices.contains(choice))) return original;
    return QuizQuestion(prompt: translated.prompt,
      choices: original.choices.map((choice) => translated.choices[canonical.choices.indexOf(choice)]).toList(),
      correctAnswerIndex: original.correctAnswerIndex, passage: original.passage);
  }
}
