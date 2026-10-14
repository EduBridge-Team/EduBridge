import '../services/simple_language_service.dart';
import '../widgets/accessibility/step_by_step_lesson.dart';

/// Author-provided examples are shown once, after the complete reading content.
class LessonReadingContent {
  static String? example(Map lesson) {
    final raw = lesson['real_life_example'];
    return raw is String && raw.trim().isNotEmpty ? raw.trim() : null;
  }

  static List<LessonStep> steps(String content, {String? realLifeExample}) {
    final chunks = SimpleLanguageService.instance
        .readingLines(content, wordsPerLine: 24)
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    return [for (var i = 0; i < chunks.length; i++)
      LessonStep(title: 'الخطوة ${i + 1}', content: chunks[i],
        realLifeExample: i == chunks.length - 1 ? realLifeExample : null)];
  }
}
