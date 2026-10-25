import 'package:edubridge_app/model/evaluations/evaluation_record.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/evaluations/evaluation_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'evaluation_history_fixture.dart';

void main() {
  test('history sorts newest first independently of server list order', () {
    final data = EvaluationHistory.fromJson(8, {
      'evaluations': [
        evaluationJson(id: 10, date: '2026-09-01 09:00:00+00'),
        evaluationJson(),
        evaluationJson(id: 12, date: '2026-10-25T11:00:00+03:00'),
      ],
    });
    expect(data.records.map((record) => record.id), [12, 11, 10]);
    expect(data.records.first.plan, originalHistoryPlan);
    expect(() => data.records.clear(), throwsUnsupportedError);
    expect(
      () => data.records.first.teachingMethods.clear(),
      throwsUnsupportedError,
    );
  });
  test('nullable legacy fields and authored unknown types remain readable', () {
    final data = EvaluationRecord.fromJson({
      'id': 1,
      'child_id': 8,
      'created_at': '2026-10-25 08:00:00',
      'evaluation_type': 'تقييم مخصص',
      'teaching_methods': null,
    });
    expect(data.type, 'تقييم مخصص');
    expect(data.author, isNull);
    expect(data.plan, isNull);
    expect(data.teachingMethods, isEmpty);
  });
  final invalid = <String, Map<String, dynamic>>{
    'foreign child': {
      'evaluations': [evaluationJson(child: 99)],
    },
    'duplicate records': {
      'evaluations': [evaluationJson(), evaluationJson()],
    },
    'invalid id': {
      'evaluations': [
        {...evaluationJson(), 'id': '11'},
      ],
    },
    'missing array': {},
    'invalid field': {
      'evaluations': [
        {...evaluationJson(), 'educational_plan': 1},
      ],
    },
    'invalid methods': {
      'evaluations': [
        {...evaluationJson(), 'teaching_methods': 'not a list'},
      ],
    },
    'invalid method element': {
      'evaluations': [
        {
          ...evaluationJson(),
          'teaching_methods': [1],
        },
      ],
    },
    'invalid calendar day': {
      'evaluations': [evaluationJson(date: '2026-02-30T08:00:00Z')],
    },
    'missing date': {
      'evaluations': [
        {...evaluationJson(), 'created_at': null},
      ],
    },
    'invalid author': {
      'evaluations': [
        {...evaluationJson(), 'evaluator_name': {}},
      ],
    },
  };
  for (final entry in invalid.entries) {
    test(
      'rejects ${entry.key}',
      () => expect(
        () => EvaluationHistory.fromJson(8, entry.value),
        throwsFormatException,
      ),
    );
  }
  test(
    'repository uses existing child-scoped GET and keeps all stored records',
    () async {
      final fixture = EvaluationHistoryHttpFixture();
      final data = await fixture.repository.load();
      expect(fixture.paths, ['/evaluations/child/8']);
      expect(data.records.map((record) => record.id), [11, 10]);
    },
  );
  test(
    'malformed successful response is an error, not an empty history',
    () async {
      final fixture = EvaluationHistoryHttpFixture()
        ..records = [evaluationJson(child: 99)];
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
    },
  );
  for (final entry in {
    401: EnrollmentFailure.session,
    403: EnrollmentFailure.forbidden,
    404: EnrollmentFailure.unavailable,
    500: EnrollmentFailure.server,
  }.entries) {
    test('HTTP ${entry.key} is preserved as an error', () async {
      final fixture = EvaluationHistoryHttpFixture()..status = entry.key;
      await expectLater(
        fixture.repository.load(),
        throwsA(
          isA<EnrollmentApiException>().having(
            (e) => e.failure,
            'failure',
            entry.value,
          ),
        ),
      );
    });
  }
  test('invalid child ID never reaches HTTP', () async {
    var calls = 0;
    final repo = EvaluationHistoryRepository(
      childId: 0,
      client: EnrollmentApiClient(
        get: (path) async {
          calls++;
          return EvaluationHistoryHttpFixture().get(path);
        },
      ),
    );
    await expectLater(repo.load(), throwsA(isA<EnrollmentApiException>()));
    expect(calls, 0);
  });
}
