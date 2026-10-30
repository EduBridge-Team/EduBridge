import 'dart:async';

import 'package:edubridge_app/model/institutions/institution_enrollment_history.dart';
import 'package:edubridge_app/screens/institution_enrollment/institution_enrollment_controller.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'institution_enrollment_history_fixture.dart';

void main() {
  test('PATCH closes the scoped record and preserves identity, section and start', () async {
    final f = InstitutionHistoryFixture();
    final repository = f.repository;
    final before = (await repository.load()).records.first;
    await repository.withdraw(2);
    expect(f.patches, [{'status': 'withdrawn'}]);
    expect(f.writes, isEmpty);
    expect(f.paths, contains('/institutions/demo-institution/schools/5/academic/student-enrollments/2/status'));
    final after = await repository.load();
    expect(after.records, hasLength(2));
    final record = after.records.singleWhere((r) => r.id == 2);
    expect(record.childId, before.childId);
    expect(record.sectionId, before.sectionId);
    expect(record.start, before.start);
    expect(record.status, InstitutionEnrollmentStatus.withdrawn);
    expect(record.end, DateTime(2026, 10, 26));
  });
  for (final kind in ['closed', 'transferred', 'missing', 'scope']) {
    test('fresh $kind preflight prevents PATCH', () async {
      final f = InstitutionHistoryFixture();
      final repository = f.repository;
      await repository.load();
      var id = 2;
      switch (kind) {
        case 'closed': f.rows.first['status'] = 'withdrawn'; break;
        case 'transferred': f.rows.first['status'] = 'transferred'; break;
        case 'missing': id = 999; break;
        case 'scope': f.academic.slug = 'foreign'; break;
      }
      await expectLater(repository.withdraw(id), throwsA(isA<EnrollmentApiException>()));
      expect(f.patches, isEmpty);
    });
  }
  for (final kind in ['false', 'unchanged', 'identity', 'date', 'denied', 'conflict', 'uncertain']) {
    test('never reports success for $kind withdrawal', () async {
      final f = InstitutionHistoryFixture();
      switch (kind) {
        case 'false': f.patchResponse = {'updated': false}; break;
        case 'unchanged': f.applyWithdrawal = false; break;
        case 'identity': f.afterWithdrawal = () => f.rows.first['child_id'] = 99; break;
        case 'date': f.afterWithdrawal = () => f.rows.first['left_on'] = null; break;
        case 'denied': f.patchStatus = 403; break;
        case 'conflict': f.patchStatus = 409; break;
        case 'uncertain': f.afterWithdrawal = () => throw Exception('Connection lost after write'); break;
      }
      await expectLater(f.repository.withdraw(2), throwsA(isA<EnrollmentApiException>()));
      expect(f.patches, hasLength(1));
    });
  }
  for (final status in [500, 503]) {
    test('committed withdrawal with HTTP $status verification remains uncertain', () async {
      final f = InstitutionHistoryFixture()
        ..afterWithdrawalReadStatus = status;
      await expectLater(
        f.repository.withdraw(2),
        throwsA(isA<EnrollmentApiException>().having(
          (error) => error.failure, 'failure', EnrollmentFailure.uncertain,
        )),
      );
      expect(f.patches, hasLength(1));
      expect(f.rows.first['status'], 'withdrawn');
    });
  }
  test('controller serializes withdrawal and transfer while awaiting PATCH', () async {
    final f = InstitutionHistoryFixture()..addTarget();
    final gate = Completer<void>();
    f.beforeWithdrawal = () => gate.future;
    final controller = InstitutionEnrollmentController(f.repository);
    addTearDown(controller.dispose);
    await controller.reload();
    final pending = controller.withdraw(2);
    expect(controller.busy, isTrue);
    await controller.withdraw(2);
    await controller.transfer(2, 31);
    gate.complete();
    await pending;
    expect(f.patches, hasLength(1));
    expect(f.writes, isEmpty);
    expect(controller.saved, isTrue);
    expect(controller.snapshot!.records.first.status, InstitutionEnrollmentStatus.withdrawn);
  });
  test('lost response clears write choices and requires a read before another action', () async {
    final f = InstitutionHistoryFixture();
    f.afterWithdrawal = () => throw Exception('Lost response');
    final controller = InstitutionEnrollmentController(f.repository);
    addTearDown(controller.dispose);
    await controller.reload();
    await controller.withdraw(2);
    expect(controller.error, EnrollmentFailure.uncertain);
    expect(controller.saved, isFalse);
    expect(controller.snapshot, isNull);
    await controller.withdraw(2);
    expect(f.patches, hasLength(1));
    f.afterWithdrawal = null;
    await controller.reload();
    expect(controller.snapshot!.records.first.status, InstitutionEnrollmentStatus.withdrawn);
    expect(f.patches, hasLength(1));
  });
  test('denied verification read never confirms or replays the write', () async {
    final f = InstitutionHistoryFixture();
    f.afterWithdrawal = () => f.status = 403;
    final controller = InstitutionEnrollmentController(f.repository);
    addTearDown(controller.dispose);
    await controller.reload();
    await controller.withdraw(2);
    expect(controller.saved, isFalse);
    expect(controller.error, EnrollmentFailure.forbidden);
    expect(controller.snapshot, isNull);
    await controller.withdraw(2);
    expect(f.patches, hasLength(1));
  });
}
