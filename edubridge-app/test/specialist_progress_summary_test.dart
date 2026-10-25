import 'package:edubridge_app/model/specialist_progress_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty progress has no current lesson and zero counts', () {
    expect(SpecialistProgressSummary.calculate([]), {
      'total': 0, 'done': 0, 'inProgress': 0,
      'doneToday': 0, 'pct': 0, 'current': null,
    });
  });

  test('counts completed lessons by date and keeps first active lesson', () {
    final current = {'status': 'in_progress', 'lesson_id': 8};
    final progress = [
      {'status': 'done', 'completed_at': '2026-10-25 10:00:00'},
      {'status': 'done', 'completed_at': '2026-10-24T10:00:00'},
      {'status': 'done', 'completed_at': 'invalid'},
      {'status': 'done'},
      current,
      {'status': 'in_progress', 'lesson_id': 9},
      {'status': 'pending', 'completed_at': '2026-10-25'},
    ];
    final result = SpecialistProgressSummary.calculate(progress,
        now: DateTime(2026, 10, 25));
    expect(result['total'], 7);
    expect(result['done'], 4);
    expect(result['inProgress'], 2);
    expect(result['doneToday'], 1);
    expect(result['pct'], 57);
    expect(result['current'], same(current));
  });
}
