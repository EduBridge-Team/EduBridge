// دروس تجريبية لكل نوع إعاقة — للاختبار والعرض
import '../services/accessibility_service.dart';

part 'sample_lesson_data.dart';

class SampleLesson {
  final String title;
  final String content;
  final String emoji;
  final List<String> steps; // للدرس خطوة بخطوة

  const SampleLesson({
    required this.title,
    required this.content,
    required this.emoji,
    this.steps = const [],
  });
}

/// يعيد دروساً تجريبية حسب نوع الإعاقة
List<Map<String, dynamic>> getSampleLessons(DisabilityType type) =>
    _sampleLessonsFor(type);

/// يعيد إيموجي مميّز لكل إعاقة
String getDisabilityEmoji(DisabilityType type) {
  switch (type) {
    case DisabilityType.adhd:
      return '⚡';
    case DisabilityType.autismMild:
    case DisabilityType.autismSevere:
      return '🧩';
    case DisabilityType.downSyndrome:
      return '💙';
    case DisabilityType.blind:
      return '👁️';
    case DisabilityType.deaf:
      return '👂';
    case DisabilityType.stuttering:
      return '🗣️';
    case DisabilityType.speechDisorders:
      return '💬';
    case DisabilityType.mildIntellectual:
      return '🧠';
    case DisabilityType.colorBlindness:
      return '🌈';
    case DisabilityType.epilepsy:
      return '⚕️';
    case DisabilityType.other:
      return '✏️';
    case DisabilityType.none:
    default:
      return '📚';
  }
}