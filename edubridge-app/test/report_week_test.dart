import 'package:edubridge_app/utils/report_week.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local Monday before UTC midnight belongs to the previous API week', () {
    expect(reportWeekStart(DateTime.parse('2026-10-12T02:10:00+03:00')),
        DateTime.utc(2026, 10, 5));
  });

  test('API week rolls over at UTC Monday midnight', () {
    expect(reportWeekStart(DateTime.parse('2026-10-12T03:00:00+03:00')),
        DateTime.utc(2026, 10, 12));
  });

  test('week start has no time component', () {
    expect(reportWeekStart(DateTime.utc(2026, 10, 14, 18, 30)),
        DateTime.utc(2026, 10, 12));
  });
}
