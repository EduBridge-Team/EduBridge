import 'package:edubridge_app/services/weekly_report_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('current week is chosen by the server rather than the phone', () async {
    final repository = WeeklyReportRepository(get: (path) async {
      expect(path, '/reports/weekly?child_id=7');
      return http.Response('{"report":{"specialist_notes":"follow-up"}}', 200);
    });
    expect((await repository.getReport(childId: 7))!['specialist_notes'], 'follow-up');
  });

  test('historical week is sent as a date without local time', () async {
    final repository = WeeklyReportRepository(get: (path) async {
      expect(path, '/reports/weekly?child_id=7&week_start=2026-10-05');
      return http.Response('{"report":null}', 200);
    });
    expect(await repository.getReport(childId: 7,
      weekStart: DateTime(2026, 10, 5, 2, 5)), isNull);
  });

  for (final status in [401, 403, 500]) {
    test('HTTP $status is an error rather than an empty report', () async {
      final repository = WeeklyReportRepository(get: (_) async => http.Response('{}', status));
      await expectLater(repository.getReport(childId: 7), throwsException);
      await expectLater(repository.getHistory(7), throwsException);
    });
  }

  test('offline and malformed responses do not become empty reports', () async {
    final offline = WeeklyReportRepository(get: (_) async => throw http.ClientException('offline'));
    await expectLater(offline.getReport(childId: 7), throwsException);
    final malformed = WeeklyReportRepository(get: (_) async => http.Response('{}', 200));
    await expectLater(malformed.getReport(childId: 7), throwsFormatException);
  });

  test('history preserves specialist-only reports from earlier weeks', () async {
    final repository = WeeklyReportRepository(get: (path) async {
      expect(path, '/reports/weekly/child/7');
      return http.Response('{"reports":[{"week_start":"2026-10-05","specialist_notes":"follow-up","teacher_notes":null}]}', 200);
    });
    final reports = await repository.getHistory(7);
    expect(reports.single['specialist_notes'], 'follow-up');
    expect(reports.single['teacher_notes'], isNull);
  });
}
