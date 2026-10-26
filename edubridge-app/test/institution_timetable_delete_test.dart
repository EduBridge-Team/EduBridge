import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/screens/institution_timetable/institution_timetable_controller.dart';
import 'institution_timetable_fixture.dart';

void main() {
  test('deletion verifies scope, identity and server absence', () async {
    final f = InstitutionTimetableFixture(), repo = InstitutionTimetableFixture().repository;
    final entry = (await repo.load()).entries.single;
    await f.repository.removeEntry(entry);
    expect(f.deletions, ['/institutions/demo-institution/schools/5/timetable/80']);
    expect((await f.repository.load()).entries, isEmpty);
  });
  test('changed or missing class cannot be deleted', () async {
    for (final missing in [false, true]) {
      final f = InstitutionTimetableFixture();
      final entry = (await f.repository.load()).entries.single;
      if (missing) { f.rows.clear(); } else { f.rows.single['room'] = 'Changed'; }
      await expectLater(f.repository.removeEntry(entry), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.conflict)));
      expect(f.deletions, isEmpty);
    }
  });
  test('unverified or malformed success never confirms deletion', () async {
    for (final malformed in [false, true]) {
      final f = InstitutionTimetableFixture();
      final entry = (await f.repository.load()).entries.single;
      if (malformed) { f.response = {'message': ''}; } else { f.applyWrite = false; }
      await expectLater(f.repository.removeEntry(entry), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)));
      expect(f.deletions, hasLength(1));
    }
  });
  test('permission denial and lost response are never retried', () async {
    for (final lost in [false, true]) {
      final f = InstitutionTimetableFixture();
      final entry = (await f.repository.load()).entries.single;
      if (lost) { f.afterWrite = () => throw Exception('Lost response'); } else { f.deleteStatus = 403; }
      await expectLater(f.repository.removeEntry(entry), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', lost ? EnrollmentFailure.uncertain : EnrollmentFailure.forbidden)));
      expect(f.deletions, hasLength(1));
    }
  });
  test('controller serializes deletion and refresh never repeats it', () async {
    final f = InstitutionTimetableFixture(), gate = Completer<void>();
    final c = InstitutionTimetableController(f.repository);
    await c.reload();
    final entry = c.snapshot!.entries.single;
    f.beforeWrite = () => gate.future;
    final pending = c.remove(entry);
    await c.remove(entry);
    gate.complete(); await pending;
    expect(c.saved, isTrue); expect(c.snapshot!.entries, isEmpty);
    await c.reload(); expect(f.deletions, hasLength(1)); c.dispose();
  });
}
