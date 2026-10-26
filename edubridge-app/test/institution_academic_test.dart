import 'package:edubridge_app/model/institutions/institution_academic_records.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'institution_academic_fixture.dart';

void main() {
  InstitutionAcademicRecords parse(Map<String, dynamic> data) =>
      InstitutionAcademicRecords.fromJson('demo-institution', 4, 5, data);
  test(
    'real join response keeps nullable capacity and resolves FK relationships',
    () {
      final records = parse(institutionAcademicJson());
      expect(records.sections.single.capacity, isNull);
      expect(records.sections.single.teacher, 'المعلم محمود');
      expect(records.curriculum.terms.single.schoolId, 5);
      expect(records.curriculum.terms.single.yearId, 10);
      expect(() => records.sections.clear(), throwsUnsupportedError);
      expect(() => records.grades.clear(), throwsUnsupportedError);
    },
  );
  for (final field in ['id', 'organization_id']) {
    test('rejects foreign school context: $field', () {
      final data = institutionAcademicJson();
      (data['school'] as Map)[field] = 99;
      expect(() => parse(data), throwsFormatException);
    });
  }
  for (final entry in [
    ('academic_years', 'school_id'),
    ('grades', 'school_id'),
    ('subjects', 'school_id'),
    ('sections', 'academic_year_id'),
    ('sections', 'grade_id'),
    ('academic_terms', 'academic_year_id'),
  ]) {
    test('rejects foreign ${entry.$1}/${entry.$2}', () {
      final data = institutionAcademicJson();
      (data[entry.$1] as List).first[entry.$2] = 99;
      expect(() => parse(data), throwsFormatException);
    });
  }
  for (final collection in [
    'academic_years',
    'grades',
    'sections',
    'academic_terms',
    'subjects',
  ]) {
    test('rejects duplicate IDs in $collection', () {
      final data = institutionAcademicJson();
      final list = data[collection] as List;
      list.add(Map<String, dynamic>.from(list.first));
      expect(() => parse(data), throwsFormatException);
    });
  }
  test(
    'invalid capacity and out-of-year terms cannot become valid records',
    () {
      for (final capacity in [0, 501, '30', 2.5]) {
        final data = institutionAcademicJson();
        (data['sections'] as List).first['capacity'] = capacity;
        expect(() => parse(data), throwsFormatException);
      }
      final data = institutionAcademicJson();
      (data['academic_terms'] as List).first['ends_on'] = '2027-07-01';
      expect(() => parse(data), throwsFormatException);
    },
  );
  test('uses actual institution routes and verifies resolved context before school fetch', () async {
    final fixture = InstitutionAcademicFixture();
    expect((await fixture.repository.load()).school.id, 5);
    expect(fixture.paths, [
      '/institutions/my-organization',
      '/institutions/demo-institution/schools/5/academic',
    ]);
    fixture.paths.clear();
    fixture.slug = 'other-institution';
    await expectLater(
      fixture.repository.load(),
      throwsA(
        isA<EnrollmentApiException>().having(
          (e) => e.failure,
          'failure',
          EnrollmentFailure.invalidResponse,
        ),
      ),
    );
    expect(fixture.paths, ['/institutions/my-organization']);
  });
  for (final entry in [
    (401, EnrollmentFailure.session),
    (403, EnrollmentFailure.forbidden),
    (404, EnrollmentFailure.unavailable),
  ]) {
    test('preserves status ${entry.$1}', () async {
      final fixture = InstitutionAcademicFixture()..status = entry.$1;
      await expectLater(
        fixture.repository.load(),
        throwsA(
          isA<EnrollmentApiException>().having(
            (e) => e.failure,
            'failure',
            entry.$2,
          ),
        ),
      );
    });
  }
}
