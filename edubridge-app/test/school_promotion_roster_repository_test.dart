import 'dart:convert';
import 'package:edubridge_app/model/schools/promotion_roster.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/school_promotion_roster_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('school roster reads authenticated school identity and scoped years', () async {
    final paths = <String>[];
    final gateway = SchoolPromotionRosterRepository(client: EnrollmentApiClient(
      get: (path) async {
        paths.add(path);
        if (path == '/school/context') return http.Response(
          jsonEncode({'school': {'id': 5, 'name': 'School', 'organization_id': null}}), 200);
        return http.Response(jsonEncode({
          'school_id': 5, 'source_year_id': 10, 'target_year_id': 11,
          'complete': true, 'revision': 'rev1',
          'students': [
            {'enrollment_id': 101, 'child_id': 201, 'child_name': 'Sara',
              'source_grade_id': 20, 'source_section_id': 30},
          ],
          'target_sections': [
            {'id': 31, 'grade_id': 21, 'name': 'Third A', 'capacity': 20, 'occupied': 1},
          ],
        }), 200);
      },
    ));
    final roster = await gateway.load(sourceYearId: 10, targetYearId: 11);
    expect(roster.students.single.name, 'Sara');
    expect(paths, ['/school/context',
      '/school/annual-promotion/roster?source_year_id=10&target_year_id=11']);
  });

  test('foreign school roster is rejected before presentation', () async {
    final gateway = SchoolPromotionRosterRepository(client: EnrollmentApiClient(
      get: (path) async => http.Response(jsonEncode(path == '/school/context'
        ? {'school': {'id': 5, 'name': 'School', 'organization_id': null}}
        : {'school_id': 9, 'source_year_id': 10, 'target_year_id': 11,
           'complete': true, 'revision': 'rev1', 'students': [],
           'target_sections': []}), 200),
    ));
    await expectLater(gateway.load(sourceYearId: 10, targetYearId: 11),
      throwsA(isA<EnrollmentApiException>().having(
        (e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)));
  });

  test('local selections never submit an enrollment write', () {
    expect(const PromotionSelection(101, PromotionOutcome.promoted, 31)
        .toJson()['decision'], 'promoted');
  });
}
