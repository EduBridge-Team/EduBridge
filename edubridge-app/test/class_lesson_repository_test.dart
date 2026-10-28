import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'class_lesson_fixture.dart';

void main() {
  test('preserves authorized section content, zero result and goal identity', () async {
    final f = ClassLessonFixture();
    final data = await f.repository.load();
    final student = data.sections.first.lessons.single.students.single;
    expect(student.score, 0); expect(student.childId, 100); expect(student.goalId, 4);
    expect(data.sections.first.lessons.single.title, 'عنوان الدرس الأصلي 1');
    expect(() => data.sections.clear(), throwsUnsupportedError);
    expect(() => data.sections.first.lessons.single.students.clear(), throwsUnsupportedError);
    expect(f.reads, 1);
  });
  for (final mode in ['foreign-goal', 'draft-goal', 'old-approved', 'score', 'duplicate', 'contract']) {
    test('rejects invalid catalog $mode', () async {
      final f = ClassLessonFixture();
      final section = (f.data['sections'] as List).first as Map;
      final lesson = (section['lessons'] as List).single as Map;
      final student = (lesson['students'] as List).single as Map;
      final goal = student['iep_goal'] as Map;
      if (mode == 'foreign-goal') goal['child_id'] = 999;
      if (mode == 'draft-goal') goal['version_status'] = 'draft';
      if (mode == 'old-approved') goal['is_current_approved'] = false;
      if (mode == 'score') student['score'] = 11;
      if (mode == 'duplicate') (lesson['students'] as List).add(Map.from(student));
      if (mode == 'contract') f.data['contract_version'] = 2;
      await expectLater(f.repository.load(), throwsA(isA<EnrollmentApiException>().having(
        (e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)));
    });
  }
  test('missing result is unavailable and never changed to zero', () async {
    final f = ClassLessonFixture();
    final student = (((f.data['sections'] as List).first['lessons'] as List).single['students'] as List).single as Map;
    student['score'] = null; student['maximum'] = null; student['state'] = null; student['iep_goal'] = null;
    final result = (await f.repository.load()).sections.first.lessons.single.students.single;
    expect(result.score, isNull); expect(result.state, isNull); expect(result.goalId, isNull);
  });
}
