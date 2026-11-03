import 'dart:convert';

import 'package:edubridge_app/model/iep/iep_edit_source.dart';
import 'package:edubridge_app/model/iep/iep_plan_history.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/iep/iep_completion_repository.dart';
import 'package:edubridge_app/services/iep/teacher_completed_iep_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'iep_draft_save_fixture.dart';
import 'iep_http_fixture.dart';

const _headers = {'content-type': 'application/json; charset=utf-8'};
http.Response _json(Object value, [int status = 200]) =>
    http.Response(jsonEncode(value), status, headers: _headers);

class _CompletionFixture {
  bool published = false;
  bool canComplete = true;
  bool forceReceiptMismatch = false;
  bool failReadback = false;
  int optionsStatus = 200;
  final posts = <String>[];
  final bodies = <Map<String, dynamic>>[];
  String revision = 'rev-1';
  Map<String, dynamic> plan = newSavedPlan();

  _CompletionFixture() {
    (plan['versions'] as List).single['status'] = 'completed';
  }

  EnrollmentApiClient get client => EnrollmentApiClient(
    get: (path) async {
      if (path == '/children/8/iep-completion-options') return _json({
        'contract_version': 1, 'child_id': 8, 'can_complete': canComplete,
        'revision': revision, 'evaluation_ids': [11],
      }, optionsStatus);
      if (path == '/children/8/iep-plans') return _json({
        'child_id': 8, 'plans': [
          if (published && !failReadback) plan,
        ],
      });
      throw StateError('Unexpected GET $path');
    },
    post: (path, body) async {
      posts.add(path);
      bodies.add(Map<String, dynamic>.from(body));
      published = true;
      return _json({
        'child_id': forceReceiptMismatch ? 50 : 8,
        'request_key': body['request_key'],
        'status': 'completed',
        'plan': plan,
      }, 201);
    },
  );
}

void main() {
  test('Done creates exactly one completed plan and confirms specialist history', () async {
    final f = _CompletionFixture();
    final gateway = IepCompletionRepository(childId: 8, client: f.client);
    final options = await gateway.options();
    await gateway.complete(saveDraft(), options, 'a' * 32);
    expect(f.posts, ['/children/8/iep-plans/complete']);
    expect(f.bodies.single['expected_revision'], 'rev-1');
    expect(f.bodies.single['evaluation_id'], 11);
    expect(f.bodies.single['request_key'], 'a' * 32);
    expect(f.bodies.single.containsKey('ministry_id'), isFalse);
  });

  test('Done refuses unauthorized and stale options before any write', () async {
    final f = _CompletionFixture()..canComplete = false;
    final gateway = IepCompletionRepository(childId: 8, client: f.client);
    final options = await gateway.options();
    await expectLater(gateway.complete(saveDraft(), options, 'a' * 32),
        throwsA(isA<EnrollmentApiException>()));
    f.canComplete = true;
    f.revision = 'rev-2';
    await expectLater(gateway.complete(saveDraft(), options, 'a' * 32),
        throwsA(isA<EnrollmentApiException>()));
    expect(f.posts, isEmpty);
  });

  test('missing backend options cannot silently publish a plan', () async {
    final f = _CompletionFixture()..optionsStatus = 404;
    final gateway = IepCompletionRepository(childId: 8, client: f.client);
    await expectLater(gateway.options(), throwsA(isA<EnrollmentApiException>()
      .having((e) => e.failure, 'failure', EnrollmentFailure.unavailable)));
    expect(f.posts, isEmpty);
  });

  for (final mode in ['receipt', 'history']) {
    test('ambiguous publish $mode never reports success or repeats writes', () async {
      final f = _CompletionFixture()
        ..forceReceiptMismatch = mode == 'receipt'
        ..failReadback = mode == 'history';
      final gateway = IepCompletionRepository(childId: 8, client: f.client);
      await expectLater(gateway.complete(saveDraft(), await gateway.options(), 'a' * 32),
          throwsA(isA<EnrollmentApiException>().having((e) =>
              e.failure, 'failure', EnrollmentFailure.uncertain)));
      expect(f.posts.length, 1);
    });
  }

  test('teacher accepts only complete, correctly scoped plans', () async {
    final f = _CompletionFixture()..published = true;
    final gateway = TeacherCompletedIepHistoryRepository(childId: 8, client:
        EnrollmentApiClient(get: (path) async {
          expect(path, '/teachers/me/children/8/completed-iep-plans');
          return _json({
            'contract_version': 1, 'complete': true, 'child_id': 8,
            'plans': [f.plan],
          });
        }));
    final plans = await gateway.load();
    expect(plans.plans.single.versions.single.status.name, 'completed');
  });

  test('teacher catalog rejects private drafts even when returned by server', () async {
    final f = _CompletionFixture();
    (f.plan['versions'] as List).single['status'] = 'draft';
    final gateway = TeacherCompletedIepHistoryRepository(childId: 8,
      client: EnrollmentApiClient(get: (_) async => _json({
        'contract_version': 1, 'complete': true, 'child_id': 8,
        'plans': [f.plan],
      })));
    await expectLater(gateway.load(), throwsA(isA<EnrollmentApiException>()
        .having((e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)));
  });

  test('teacher catalog rejects foreign child, incomplete response and 404', () async {
    for (final mode in ['foreign', 'incomplete', 'unavailable']) {
      final gateway = TeacherCompletedIepHistoryRepository(childId: 8,
        client: EnrollmentApiClient(get: (_) async => _json({
          'contract_version': 1, 'complete': mode != 'incomplete',
          'child_id': mode == 'foreign' ? 90 : 8, 'plans': [],
        }, mode == 'unavailable' ? 404 : 200)));
      await expectLater(gateway.load(), throwsA(isA<EnrollmentApiException>()));
    }
  });

  test('existing saved plan remains an independent editable draft', () {
    final plan = IepPlan.fromJson(newSavedPlan());
    expect(IepEditSource.capture(plan, plan.versions.single).versionId, 103);
  });
}
