import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'teacher_sections_fixture.dart';
void main() {
  test('preserves scoped sections, subjects and unavailable versus explicit zero progress', () async {
    final f = TeacherSectionsFixture();
    final repository = f.repository, sections = await repository.sections();
    expect(sections.sections.first.name, 'شعبة 1'); expect(sections.sections.first.subjects[1], 'مادة 1');
    final roster = await repository.students(sections.sections.first);
    expect(roster.students.first['progress_percentage'], isNull); expect(roster.students.last['progress_percentage'], 0);
    expect(() => sections.sections.clear(), throwsUnsupportedError);
    expect(() => roster.students.first['name'] = 'changed', throwsUnsupportedError);
    expect(f.reads, 1); expect(f.rosterReads, 1);
  });
  for (final mode in ['duplicate-section', 'duplicate-subject', 'contract']) {
    test('rejects invalid catalog $mode', () async {
      final f = TeacherSectionsFixture();
      final sections = f.data['sections'] as List;
      if (mode == 'duplicate-section') sections.add(sectionJson(sections.first));
      if (mode == 'duplicate-subject') (sections.first['subjects'] as List).add(sectionJson((sections.first['subjects'] as List).first));
      if (mode == 'contract') f.data['contract_version'] = 2;
      await expectLater(f.repository.sections(), throwsA(isA<EnrollmentApiException>()));
    });
  }
  for (final mode in ['school', 'year', 'section', 'duplicate-child', 'progress']) {
    test('rejects foreign or malformed roster $mode', () async {
      final f = TeacherSectionsFixture();
      final source = (await f.repository.sections()).sections.first;
      if (mode == 'school') f.rosters[1]!['school_id'] = 2;
      if (mode == 'year') f.rosters[1]!['academic_year_id'] = 2;
      if (mode == 'section') f.rosters[1]!['section_id'] = 2;
      if (mode == 'duplicate-child') (f.rosters[1]!['students'] as List).add(sectionJson((f.rosters[1]!['students'] as List).first));
      if (mode == 'progress') (f.rosters[1]!['students'] as List).first['progress_percentage'] = 101;
      await expectLater(f.repository.students(source), throwsA(isA<EnrollmentApiException>()));
    });
  }
  test('unsupported sections never fall back to individual child assignment', () async {
    final f = TeacherSectionsFixture()..sectionStatus = 404;
    await expectLater(f.repository.sections(), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.unavailable)));
    expect(f.rosterReads, 0);
  });
}
