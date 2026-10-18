import 'package:edubridge_app/models/interactive_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> sample() => {
        'schema_version': '1.0.0',
        'locale': 'ar-PS',
        'templates': [
          {
            'id': 'arabic-01',
            'subject': 'arabic',
            'title': 'حرف الألف',
            'objective': 'يميز حرف الألف',
            'steps': [
              {'id': 'intro', 'type': 'explanation', 'text': 'هذا حرف الألف'},
              {
                'id': 'q1',
                'type': 'single_choice',
                'prompt': 'اختر الألف',
                'options': [
                  {'id': 'a', 'text': 'أ'},
                  {'id': 'b', 'text': 'ب'}
                ],
                'correct_option_id': 'a'
              }
            ]
          }
        ]
      };

  test('parses a valid lesson and scores a practice answer', () {
    final catalog = InteractiveLessonCatalog.fromJson(sample());
    expect(catalog.templates, hasLength(1));
    final lesson = catalog.templates.single;
    expect(lesson.steps.first, isA<LessonExplanation>());
    final question = lesson.steps.last as LessonSingleChoice;
    expect(question.isCorrect('a'), isTrue);
    expect(question.isCorrect('b'), isFalse);
    expect(question.isCorrect('not-an-option'), isFalse);
  });

  test('rejects a missing correct option', () {
    final json = sample();
    final template = (json['templates'] as List).single as Map<String, dynamic>;
    final question = (template['steps'] as List).last as Map<String, dynamic>;
    question['correct_option_id'] = 'missing';
    expect(() => InteractiveLessonCatalog.fromJson(json), throwsFormatException);
  });

  test('rejects duplicate step ids', () {
    final json = sample();
    final template = (json['templates'] as List).single as Map<String, dynamic>;
    final steps = template['steps'] as List;
    (steps.last as Map<String, dynamic>)['id'] = 'intro';
    expect(() => InteractiveLessonCatalog.fromJson(json), throwsFormatException);
  });

  test('rejects unknown step types', () {
    final json = sample();
    final template = (json['templates'] as List).single as Map<String, dynamic>;
    (template['steps'] as List).first['type'] = 'unsupported';
    expect(() => InteractiveLessonCatalog.fromJson(json), throwsFormatException);
  });

  test('rejects duplicate lesson ids', () {
    final json = sample();
    final templates = json['templates'] as List;
    templates.add(templates.first);
    expect(() => InteractiveLessonCatalog.fromJson(json), throwsFormatException);
  });
}
