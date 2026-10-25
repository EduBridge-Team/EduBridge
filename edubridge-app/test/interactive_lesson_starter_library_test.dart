import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/models/interactive_lesson.dart';
import 'package:edubridge_app/services/interactive_lesson_starter_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled Arabic starter library loads six playable templates', () async {
    final catalog = await const InteractiveLessonStarterRepository().load();
    expect(catalog.schemaVersion, '1.0.0');
    expect(catalog.locale, 'ar-PS');
    expect(catalog.templates, hasLength(6));
    expect(catalog.templates.map((lesson) => lesson.id).toSet(), hasLength(6));
    for (final lesson in catalog.templates) {
      expect(lesson.title, isNotEmpty);
      expect(lesson.objective, isNotEmpty);
      expect(lesson.steps, isNotEmpty);
      for (final step in lesson.steps) {
        if (step is LessonSingleChoice) {
          expect(step.options, hasLength(greaterThanOrEqualTo(2)));
          expect(step.options.any((o) => o.id == step.correctOptionId), isTrue);
          expect(step.isCorrect(step.correctOptionId), isTrue);
        }
      }
    }
  });

  test('duplicate lesson IDs and invalid answer keys fail validation', () {
    final lesson = {
      'id': 'sample', 'subject': 'arabic', 'title': 'Sample',
      'objective': 'Practice',
      'steps': [
        {
          'id': 'question', 'type': 'single_choice', 'prompt': 'Pick one',
          'options': [
            {'id': 'a', 'text': 'A'}, {'id': 'b', 'text': 'B'},
          ],
          'correct_option_id': 'a',
        },
      ],
    };
    final first = {
      'schema_version': '1.0.0', 'locale': 'ar-PS',
      'templates': [lesson, lesson],
    };
    expect(() => InteractiveLessonCatalog.fromJson(first), throwsFormatException);
    final invalid = jsonDecode(jsonEncode(lesson)) as Map<String, dynamic>;
    (invalid['steps'] as List).first['correct_option_id'] = 'missing';
    expect(
      () => InteractiveLessonCatalog.fromJson({
        'schema_version': '1.0.0', 'locale': 'ar-PS', 'templates': [invalid],
      }),
      throwsFormatException,
    );
  });

  test('empty steps and unsupported step types are rejected', () {
    Map<String, dynamic> catalog(List<dynamic> steps) => {
      'schema_version': '1.0.0', 'locale': 'ar-PS',
      'templates': [
        {
          'id': 'sample', 'subject': 'math', 'title': 'Numbers',
          'objective': 'Count', 'steps': steps,
        },
      ],
    };
    expect(() => InteractiveLessonCatalog.fromJson(catalog([])), throwsFormatException);
    expect(
      () => InteractiveLessonCatalog.fromJson(catalog([
        {'id': 'x', 'type': 'video'},
      ])),
      throwsFormatException,
    );
  });
}
