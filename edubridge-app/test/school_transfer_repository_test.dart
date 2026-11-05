import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'school_transfer_fixture.dart';

Matcher failure(EnrollmentFailure value) =>
    isA<EnrollmentApiException>().having((e) => e.failure, 'failure', value);
void main() {
  test(
      'create remains pending guardian and sends only authorized enrollment/destination',
      () async {
    final f = SchoolTransferFixture();
    final data = await f.repository.load();
    expect(data.enrollments.single.childId, 30);
    expect(await f.repository.create(10, 9, ' reason '), 50);
    expect(f.writes.single.$2, {
      'source_enrollment_id': 10,
      'destination_school_id': 9,
      'reason': 'reason'
    });
    expect(() => data.incoming.clear(), throwsUnsupportedError);
  });
  for (final accept in [true, false]) {
    test(
        'destination decision validates pending version and exact receipt $accept',
        () async {
      final f = SchoolTransferFixture()..postStatus = accept ? 201 : 200;
      final request = (await f.repository.load()).incoming.single;
      await f.repository.decide(request,
          accept: accept, section: 21, key: '0123456789abcdef');
      expect(f.writes.single.$1, '/school/transfers/40/decision');
      expect(f.writes.single.$2, {
        'decision': accept ? 'accept' : 'reject',
        'version': 2,
        if (accept) 'section_id': 21,
        if (accept) 'idempotency_key': '0123456789abcdef'
      });
    });
  }
  for (final mode in [
    'scope',
    'permission',
    'malformed',
    'duplicate',
    'foreign',
    'status',
    'same-school'
  ]) {
    test('rejects invalid or unauthorized directory $mode', () async {
      final f = SchoolTransferFixture();
      switch (mode) {
        case 'scope':
          f.school = 6;
        case 'permission':
          f.allowed = false;
        case 'malformed':
          f.incoming = [null];
        case 'duplicate':
          f.incoming.add({...f.incoming.single as Map});
        case 'foreign':
          (f.incoming.single as Map)['destination_school_id'] = 9;
        case 'status':
          (f.incoming.single as Map)['status'] = 'pending_guardian';
        case 'same-school':
          (f.incoming.single as Map)['source_school_id'] = 5;
      }
      await expectLater(
          f.repository.load(), throwsA(isA<EnrollmentApiException>()));
      expect(f.writes, isEmpty);
    });
  }
  for (final mode in ['version', 'child', 'missing', 'section', 'permission']) {
    test('changed decision source blocks write $mode', () async {
      final f = SchoolTransferFixture();
      final request = (await f.repository.load()).incoming.single;
      switch (mode) {
        case 'version':
          (f.incoming.single as Map)['version'] = 3;
        case 'child':
          (f.incoming.single as Map)['child_id'] = 999;
        case 'missing':
          f.incoming = [];
        case 'section':
          f.sections = [];
        case 'permission':
          f.allowed = false;
      }
      await expectLater(
          f.repository.decide(request,
              accept: true, section: 21, key: '0123456789abcdef'),
          throwsA(isA<EnrollmentApiException>()));
      expect(f.writes, isEmpty);
    });
  }
  for (final mode in ['source', 'destination']) {
    test('create revalidates selected $mode before write', () async {
      final f = SchoolTransferFixture();
      await f.repository.load();
      if (mode == 'source') {
        (f.enrollments.single as Map)['status'] = 'transferred';
      } else {
        f.schools = [];
      }
      await expectLater(f.repository.create(10, 9, ''),
          throwsA(failure(EnrollmentFailure.conflict)));
      expect(f.writes, isEmpty);
    });
  }
  for (final receipt in [
    {},
    {'request_id': 0, 'status': 'pending_guardian'},
    {'request_id': 50, 'status': 'completed'}
  ]) {
    test('unconfirmed create is uncertain and sent once $receipt', () async {
      final f = SchoolTransferFixture()
        ..receipt = Map<String, dynamic>.from(receipt);
      await expectLater(f.repository.create(10, 9, ''),
          throwsA(failure(EnrollmentFailure.uncertain)));
      expect(f.writes, hasLength(1));
    });
  }
  test('server failure after submission is uncertain', () async {
    final f = SchoolTransferFixture()..postStatus = 500;
    await expectLater(f.repository.create(10, 9, ''),
        throwsA(failure(EnrollmentFailure.uncertain)));
    expect(f.writes, hasLength(1));
  });
  test('wrong destination receipt cannot confirm transfer', () async {
    final f = SchoolTransferFixture()
      ..receipt = {
        'request_id': 99,
        'status': 'completed',
        'enrollment_id': 60
      };
    final request = (await f.repository.load()).incoming.single;
    await expectLater(
        f.repository.decide(request,
            accept: true, section: 21, key: '0123456789abcdef'),
        throwsA(failure(EnrollmentFailure.uncertain)));
    expect(f.writes, hasLength(1));
  });
}
