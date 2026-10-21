import '../l10n/generated/app_localizations.dart';
import '../features/games/data/learning_question_bank.dart';
import '../features/games/domain/quiz_question.dart';

/// Translate built-in presentation after shuffling, preserving answer indexes.
abstract final class ReadingGameDisplay {
  static QuizQuestion question(QuizQuestion original, AppLocalizations strings) {
    final translated = switch (original.prompt) {
      'لماذا ذهب سامر إلى المكتبة؟' => (passage: strings.readingPassageLibrary, prompt: strings.readingQuestionLibrary, choices: [strings.readingLibraryOption0, strings.readingLibraryOption1, strings.readingLibraryOption2, strings.readingLibraryOption3]),
      'ما الذي ساعد البذور على النمو؟' => (passage: strings.readingPassageSeeds, prompt: strings.readingQuestionSeeds, choices: [strings.readingSeedsOption0, strings.readingSeedsOption1, strings.readingSeedsOption2, strings.readingSeedsOption3]),
      'ما هدف الصندوق؟' => (passage: strings.readingPassageRecycling, prompt: strings.readingQuestionRecycling, choices: [strings.readingRecyclingOption0, strings.readingRecyclingOption1, strings.readingRecyclingOption2, strings.readingRecyclingOption3]),
      'كيف ساعدت مريم صديقتها؟' => (passage: strings.readingPassageSharing, prompt: strings.readingQuestionSharing, choices: [strings.readingSharingOption0, strings.readingSharingOption1, strings.readingSharingOption2, strings.readingSharingOption3]),
      'لماذا حمل خالد مظلته؟' => (passage: strings.readingPassageRain, prompt: strings.readingQuestionRain, choices: [strings.readingRainOption0, strings.readingRainOption1, strings.readingRainOption2, strings.readingRainOption3]),
      'ماذا وضعت سلمى للعصفور؟' => (passage: strings.readingPassageBird, prompt: strings.readingQuestionBird, choices: [strings.readingBirdOption0, strings.readingBirdOption1, strings.readingBirdOption2, strings.readingBirdOption3]),
      'ماذا فعل يوسف أولاً؟' => (passage: strings.readingPassageSalad, prompt: strings.readingQuestionSalad, choices: [strings.readingSaladOption0, strings.readingSaladOption1, strings.readingSaladOption2, strings.readingSaladOption3]),
      'ماذا فعل رامي بعد القراءة؟' => (passage: strings.readingPassageStory, prompt: strings.readingQuestionStory, choices: [strings.readingStoryOption0, strings.readingStoryOption1, strings.readingStoryOption2, strings.readingStoryOption3]),
      'ما الذي ارتدته هناء لحماية رأسها؟' => (passage: strings.readingPassageBicycle, prompt: strings.readingQuestionBicycle, choices: [strings.readingBicycleOption0, strings.readingBicycleOption1, strings.readingBicycleOption2, strings.readingBicycleOption3]),
      'لماذا جمع الأطفال النفايات؟' => (passage: strings.readingPassageBeach, prompt: strings.readingQuestionBeach, choices: [strings.readingBeachOption0, strings.readingBeachOption1, strings.readingBeachOption2, strings.readingBeachOption3]),
      'أي نبتة نمت؟' => (passage: strings.readingPassagePlants, prompt: strings.readingQuestionPlants, choices: [strings.readingPlantsOption0, strings.readingPlantsOption1, strings.readingPlantsOption2, strings.readingPlantsOption3]),
      'كم وقتاً كان لدى آدم؟' => (passage: strings.readingPassageTime, prompt: strings.readingQuestionTime, choices: [strings.readingTimeOption0, strings.readingTimeOption1, strings.readingTimeOption2, strings.readingTimeOption3]),
      _ => null,
    };
    if (translated == null) return original;
    final canonical = LearningQuestionBank.reading.firstWhere((item) => item.prompt == original.prompt);
    // Unknown custom choices retain their original content.
    if (original.choices.any((choice) => !canonical.choices.contains(choice))) return original;
    return QuizQuestion(passage: translated.passage, prompt: translated.prompt,
      choices: original.choices.map((choice) => translated.choices[canonical.choices.indexOf(choice)]).toList(),
      correctAnswerIndex: original.correctAnswerIndex);
  }
}
