import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/model/statistics/ministry_statistics.dart';
import 'package:edubridge_app/services/ministry_statistics_repository.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';

void main() {
  test('missing metrics stay unavailable and explicit zero remains zero', () {
    final data = MinistryStatistics.fromJson(
        {'total_children': 0, 'by_disability_type': []});
    expect(data.metrics['total_children'], 0);
    expect(data.metrics['active_children'], isNull);
    expect(data.disabilities, isEmpty);
    expect(data.ages, isNull);
    expect(() => data.metrics['active_children'] = 0, throwsUnsupportedError);
  });
  for (final payload in [
    <String, dynamic>{},
    {'error': 'Denied'},
    {'success': false, 'total_children': 0},
    {'total_children': -1},
    {'total_children': '0'},
    {'total_children': 2, 'active_children': 3},
    {'homework_completion_rate': 101},
    {'homework_completion_rate': double.nan},
    {
      'by_age_group': {'0-5': -1}
    },
    {
      'by_age_group': {'0-5': '2'}
    },
    {
      'by_age_group': [1]
    }
  ]) {
    test(
        'rejects malformed ministry statistics $payload',
        () => expect(
            () => MinistryStatistics.fromJson(payload), throwsFormatException));
  }
  test('repository propagates denial rather than empty data', () async {
    final repo = MinistryStatisticsRepository(
        client:
            EnrollmentApiClient(get: (_) async => http.Response('{}', 403)));
    await expectLater(
        repo.load(),
        throwsA(isA<EnrollmentApiException>()
            .having((e) => e.failure, 'failure', EnrollmentFailure.forbidden)));
  });
  test(
      'repository accepts actual ministry response without invented date filter',
      () async {
    final repo = MinistryStatisticsRepository(
        client: EnrollmentApiClient(get: (path) async {
      expect(path, '/ministry/statistics');
      return http.Response(
          jsonEncode({
            'total_children': 4,
            'active_children': 2,
            'homework_completion_rate': 25,
            'learning_support_meetings_count': 0,
            'by_age_group': {'6-9': 4}
          }),
          200);
    }));
    expect((await repo.load()).metrics['homework_completion_rate'], 25);
  });
}
