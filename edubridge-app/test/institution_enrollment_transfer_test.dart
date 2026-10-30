import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'institution_enrollment_history_fixture.dart';

void main() {
  test('scoped transfer confirms old and new enrollments', () async {
    final f = InstitutionHistoryFixture()..addTarget();
    await f.repository.transfer(2, 31);
    expect(f.writes, [{'section_id': 31}]);
    expect(f.paths, contains('/institutions/demo-institution/schools/5/academic/student-enrollments/2/transfer'));
    final data = await f.repository.load();
    expect(data.records.first.childId, 9);
    expect(data.records.first.sectionId, 31);
    expect(data.transferTargets(3), isEmpty);
  });
  for (final failureStatus in [500, 503]) {
    test('transfer confirmation HTTP $failureStatus is uncertain and not retried', () async {
      final fixture = InstitutionHistoryFixture()
        ..addTarget()
        ..afterTransferReadStatus = failureStatus;
      await expectLater(
        fixture.repository.transfer(2, 31),
        throwsA(isA<EnrollmentApiException>().having(
          (error) => error.failure, 'failure', EnrollmentFailure.uncertain,
        )),
      );
      expect(fixture.writes, hasLength(1));
      expect(fixture.rows.last['status'], 'active');
    });
  }
  for (final kind in ['same', 'missing', 'inactive', 'used', 'year', 'scope']) {
    test('rejects $kind before sending', () async {
      final f = InstitutionHistoryFixture()..addTarget();
      var target = 31;
      switch (kind) {
        case 'same': target = 30; break;
        case 'missing': target = 999; break;
        case 'inactive': f.rows.first['status'] = 'withdrawn'; break;
        case 'used': f.rows.add({...f.rows.last, 'id': 4, 'child_id': 9, 'section_id': 31}); break;
        case 'year':
          final years = f.academic.data['academic_years'] as List;
          f.academic.data['academic_years'] = [...years, {...Map<String, dynamic>.from(years.first as Map), 'id': 11, 'is_current': false}];
          (f.academic.data['sections'] as List).last['academic_year_id'] = 11;
          break;
        case 'scope': f.academic.slug = 'other'; break;
      }
      await expectLater(f.repository.transfer(2, target), throwsA(isA<EnrollmentApiException>()));
      expect(f.writes, isEmpty);
    });
  }
  for (final kind in ['false', 'unchanged', 'conflict', 'forbidden']) {
    test('does not confirm $kind response', () async {
      final f = InstitutionHistoryFixture()..addTarget();
      switch (kind) {
        case 'false': f.postResponse = {'transferred': false}; break;
        case 'unchanged': f.applyTransfer = false; break;
        case 'conflict': f.postStatus = 409; break;
        case 'forbidden': f.postStatus = 403; break;
      }
      await expectLater(f.repository.transfer(2, 31), throwsA(isA<EnrollmentApiException>()));
      expect(f.writes, hasLength(1));
    });
  }
}
