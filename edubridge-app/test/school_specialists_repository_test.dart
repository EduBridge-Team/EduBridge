import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/screens/institution_specialists/school_specialists_controller.dart';
import 'school_specialists_fixture.dart';

void main() {
  test('school assignment never includes children; confirms exact creation and ending', () async {
    final f = SchoolSpecialistsFixture(), repo = f.repository;
    final before = await repo.load();
    expect(before.canAdd(7), isTrue); expect(before.canAdd(8), isFalse);
    await repo.assign(before, 7);
    final body = f.posts.single;
    expect(body['specialist_id'], 7);
    expect(body.keys, unorderedEquals(['specialist_id', 'expected_revision', 'effective_on', 'idempotency_key']));
    expect(body['idempotency_key'], matches(RegExp(r'^[0-9a-f]{32}$')));
    final fresh = await repo.load();
    await repo.end(fresh, fresh.assignments.singleWhere((a) => a.id == 10));
    expect(f.posts.last['expected_specialist_id'], 8);
    expect((await repo.load()).assignments.singleWhere((a) => a.id == 10).active, isFalse);
    expect(f.paths.every((p) => p.startsWith('/institutions/demo/schools/2/specialist-assignments')), isTrue);
  });
  for (final issue in ['scope', 'contract', 'partial', 'duplicate', 'active-duplicate', 'end-before-start']) {
    test('rejects malformed catalog $issue', () async {
      final f = SchoolSpecialistsFixture();
      final list = f.data['assignments'] as List;
      if (issue == 'scope') f.data['school_id'] = 3;
      if (issue == 'contract') f.data['contract_version'] = 2;
      if (issue == 'partial') f.data['complete'] = false;
      if (issue == 'duplicate') list.add(Map<String, dynamic>.of(list.first as Map<String, dynamic>));
      if (issue == 'active-duplicate') list.add({...list.first as Map<String, dynamic>, 'id': 12});
      if (issue == 'end-before-start') { list.first['ended_on'] = '2026-01-01'; list.first['can_end'] = false; }
      await expectLater(f.repository.load(), throwsA(isA<EnrollmentApiException>()));
    });
  }
  for (final change in ['revision', 'capability', 'eligibility', 'duplicate']) {
    test('preflight rejects changed $change without writing', () async {
      final f = SchoolSpecialistsFixture(), before = await f.repository.load();
      if (change == 'revision') f.data['revision'] = 'r2';
      if (change == 'capability') f.data['capabilities']['can_assign'] = false;
      if (change == 'eligibility') f.data['eligible_specialists'] = <Object>[];
      if (change == 'duplicate') (f.data['assignments'] as List).add({
        'id': 12, 'specialist_id': 7, 'specialist_name': 'existing',
        'starts_on': '2026-09-01', 'ended_on': null, 'can_end': true});
      await expectLater(f.repository.assign(before, 7), throwsA(isA<EnrollmentApiException>()));
      expect(f.posts, isEmpty);
    });
  }
  for (final issue in ['receipt', 'readback', 'missing-record']) {
    test('unverified successful write clears actionable snapshot $issue', () async {
      final f = SchoolSpecialistsFixture(), state = SchoolSpecialistsController(f.repository);
      await state.reload();
      f.badReceipt = issue == 'receipt'; f.failAfter = issue == 'readback'; f.skipPersistence = issue == 'missing-record';
      await state.assign(state.snapshot!, 7);
      expect(state.saved, isFalse); expect(state.snapshot, isNull); expect(state.canWrite, isFalse);
      expect(f.posts, hasLength(1)); await state.reload();
      expect(f.posts, hasLength(1)); state.dispose();
    });
  }
  test('unsupported service stays unavailable, never a care-team fallback', () async {
    final f = SchoolSpecialistsFixture()..status = 404;
    await expectLater(f.repository.load(), throwsA(isA<EnrollmentApiException>()
      .having((e) => e.failure, 'failure', EnrollmentFailure.unavailable)));
    expect(f.posts, isEmpty); expect(f.paths, hasLength(1));
  });
}

