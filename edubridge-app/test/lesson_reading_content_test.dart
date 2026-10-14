import 'package:edubridge_app/utils/lesson_reading_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reading retains all words and attaches the example once to the final step', () {
    final words = List.generate(55, (index) => 'كلمة$index');
    final steps = LessonReadingContent.steps(words.join(' '), realLifeExample: 'نعد الملاعق');
    expect(steps.length, 3);
    expect(steps.map((step) => step.content).join(' '), words.join(' '));
    expect(steps.where((step) => step.realLifeExample != null).length, 1);
    expect(steps.last.realLifeExample, 'نعد الملاعق');
  });

  test('old lessons and invalid examples do not invent educational content', () {
    expect(LessonReadingContent.example({}), isNull);
    expect(LessonReadingContent.example({'real_life_example': []}), isNull);
    expect(LessonReadingContent.example({'real_life_example': '  '}), isNull);
    expect(LessonReadingContent.example({'real_life_example': ' نعد الملاعق '}), 'نعد الملاعق');
    expect(LessonReadingContent.steps(''), isEmpty);
    expect(LessonReadingContent.steps('درس قصير').single.realLifeExample, isNull);
  });
}
