import 'dart:convert';

import 'package:edubridge_app/model/schools/curriculum_draft.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/institution_curriculum_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'institution_academic_fixture.dart';

void main() {
  for (final kind in CurriculumKind.values) {
    for (final failure in ['none', 'name', 'school', 'id', 'context', 'parent', 'status']) {
      test('institution ${kind.name} receipt: $failure', () async {
        final fixture = InstitutionAcademicFixture();
        final writes = <({String path, Map<String, dynamic> body})>[];
        final repository = InstitutionCurriculumRepository(
          organizationSlug: 'demo-institution', organizationId: 4,
          schoolId: 5,
          client: EnrollmentApiClient(
            get: fixture.get,
            post: (path, body) async {
              writes.add((path: path, body: body));
              if (failure == 'status') return http.Response('{}', 403);
              return http.Response(jsonEncode({
                kind == CurriculumKind.term ? 'term' : 'subject': {
                  ...body,
                  'id': failure == 'id' ? (kind == CurriculumKind.term ? 40 : 50) : 100,
                  if (kind == CurriculumKind.term) 'academic_year_id': 10,
                  if (kind == CurriculumKind.subject || failure == 'school')
                    'school_id': failure == 'school' ? 6 : 5,
                  if (failure == 'name') 'name': 'Wrong receipt',
                },
              }), 201, headers: {'content-type': 'application/json; charset=utf-8'});
            },
          ),
        );
        await repository.load();
        if (failure == 'context') fixture.slug = 'other-institution';
        if (failure == 'parent') {
          fixture.data['academic_years'] = [];
          fixture.data['academic_terms'] = [];
          fixture.data['sections'] = [];
        }
        final draft = CurriculumDraft(
          kind: kind, name: ' سجل جديد ', yearId: 10, position: 2,
          start: DateTime(2027, 2, 1), end: DateTime(2027, 6, 30),
          code: ' SCI ', active: false,
        );
        final succeeds = failure == 'none' ||
            (failure == 'parent' && kind == CurriculumKind.subject);
        if (succeeds) {
          await repository.create(5, draft);
          expect(writes.single.path,
            '/institutions/demo-institution/schools/5/academic/${kind == CurriculumKind.term ? 'years/10/terms' : 'subjects'}');
          final expected = draft.toJson()..remove('academic_year_id');
          expect(writes.single.body, expected);
        } else {
          await expectLater(repository.create(5, draft), throwsA(isA<EnrollmentApiException>()));
          expect(writes.length, failure == 'context' || failure == 'parent' ? 0 : 1);
        }
      });
    }
  }
}
