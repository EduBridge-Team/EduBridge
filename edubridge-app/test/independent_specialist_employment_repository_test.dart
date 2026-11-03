import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/independent_specialist_employment_repository.dart';

class _EmploymentFixture {
  String actorRole = 'specialist';
  bool independent = true, director = true;
  int schoolId = 10, actorId = 2;
  bool accepted = false, ended = false;
  bool badAcceptanceReceipt = false;
  final paths = <String>[];
  final posts = <Map<String, dynamic>>[];

  late final gateway = IndependentSpecialistEmploymentRepository(
    client: EnrollmentApiClient(
      get: (path) async {
        paths.add(path);
        final Map<String, dynamic> data;
        if (path == '/me') {
          data = {'user': {'id': actorId, 'role': actorRole}};
        } else if (path == '/school/context') {
          data = {'school': {
            'id': schoolId,
            'organization_id': independent ? null : 77,
          }};
        } else if (path == '/school/delegation') {
          data = {'school': {
            'id': schoolId,
          }, 'role': director ? 'director' : 'deputy_director'};
        } else if (path == '/school/specialist-employments') {
          data = {
            'complete': true,
            'school_id': 10,
            'employments': [
              {'id': 9, 'specialist_id': 2, 'specialist_name': 'مختص',
                'specialist_email': 'specialist@example.test',
                'accepted_at': accepted ? '2026-11-03T01:00:00Z' : null,
                'ended_at': ended ? '2026-11-03T02:00:00Z' : null},
            ],
          };
        } else if (path == '/specialists/me/school-employments') {
          data = {
            'complete': true,
            'specialist_id': 2,
            'employments': [
              {'id': 9, 'school_id': 10, 'school_name': 'مدرسة الريادة',
                'accepted_at': accepted ? '2026-11-03T01:00:00Z' : null},
            ],
          };
        } else {
          throw StateError('Unexpected URL: $path');
        }
        return http.Response(jsonEncode(data), 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      },
      post: (path, body) async {
        paths.add(path);
        posts.add(Map<String, dynamic>.from(body));
        if (path == '/specialists/me/school-employments/9/accept') {
          accepted = true;
          return http.Response(jsonEncode({
            'school_id': badAcceptanceReceipt ? 99 : 10,
            'employment_id': 9,
            'status': 'active',
          }), 200);
        }
        if (path == '/school/specialist-employments') {
          return http.Response(jsonEncode({
            'school_id': 10, 'employment_id': 11, 'status': 'pending',
          }), 201);
        }
        if (path == '/school/specialist-employments/9/end') {
          ended = true;
          return http.Response(jsonEncode({
            'school_id': 10, 'employment_id': 9, 'ended': true,
          }), 200);
        }
        throw StateError('Unexpected POST: $path');
      },
    ),
  );
}

void main() {
  test('specialist explicitly accepts offer; confirms readback and scope', () async {
    final f = _EmploymentFixture();
    final before = await f.gateway.myOffers();
    expect(before.single.accepted, isFalse);
    expect(before.single.schoolId, 10);
    expect(f.posts, isEmpty);
    await f.gateway.accept(9);
    expect(f.posts, hasLength(1));
    expect((await f.gateway.myOffers()).single.accepted, isTrue);
    expect(f.paths.where((p) => p == '/me').length, greaterThanOrEqualTo(4));
  });

  test('director offers employment and only manages matching school staff', () async {
    final f = _EmploymentFixture();
    final before = await f.gateway.directorRoster(10);
    expect(before.single.specialistId, 2);
    expect(before.single.accepted, isFalse);
    await f.gateway.invite(10, ' Specialist@Example.test ');
    expect(f.posts.single['expected_school_id'], 10);
    expect(f.posts.single['email'], 'specialist@example.test');
    await f.gateway.end(10, 9);
    expect(f.ended, isTrue);
    expect((await f.gateway.directorRoster(10)).single.ended, isTrue);
  });

  test('another school and a deputy cannot send an employment offer', () async {
    final f = _EmploymentFixture();
    f.schoolId = 99;
    await expectLater(f.gateway.invite(10, 'specialist@example.test'),
        throwsA(isA<EnrollmentApiException>()));
    f.schoolId = 10;
    f.director = false;
    await expectLater(f.gateway.invite(10, 'specialist@example.test'),
        throwsA(isA<EnrollmentApiException>()));
    f.director = true;
    f.independent = false;
    await expectLater(f.gateway.invite(10, 'specialist@example.test'),
        throwsA(isA<EnrollmentApiException>()));
    expect(f.posts, isEmpty);
  });

  test('role change and forged receipt cannot confirm acceptance', () async {
    final f = _EmploymentFixture();
    f.actorRole = 'teacher';
    await expectLater(f.gateway.myOffers(), throwsA(isA<EnrollmentApiException>()));
    f.actorRole = 'specialist';
    f.badAcceptanceReceipt = true;
    await expectLater(f.gateway.accept(9), throwsA(isA<EnrollmentApiException>()));
    expect(f.posts, hasLength(1));
  });
}
