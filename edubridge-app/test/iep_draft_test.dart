import 'package:edubridge_app/model/iep/iep_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'decimal keyboard input preserves direction and rejects ambiguous values',
    () {
      for (final text in ['٢٫٥', '۲.۵', '2.5', ' 2.5 ']) {
        expect(parseIepMeasurement(text), 2.5);
      }
      expect(parseIepMeasurement('-٣٫٢'), -3.2);
      expect(parseIepMeasurement('٠'), 0);
      for (final text in [
        '',
        'NaN',
        'Infinity',
        '1e4',
        '1,000',
        '٢،٥',
        '2.5.1',
        '2 5',
        '+3',
      ]) {
        expect(parseIepMeasurement(text), isNull, reason: text);
      }
      expect(parseIepMeasurement('9' * 400), isNull);
    },
  );
  test('calendar input rejects rollover and accepts Arabic numeral sets', () {
    expect(parseIepDraftDate('٢٠٢٦-٠٩-٠١'), DateTime(2026, 9, 1));
    expect(parseIepDraftDate('۲۰۲۶-۰۹-۰۱'), DateTime(2026, 9, 1));
    for (final text in [
      '2026-02-29',
      '2026-13-01',
      '2026-09-31',
      '2026-9-1',
      '2026-09-01T12:00:00Z',
    ]) {
      expect(parseIepDraftDate(text), isNull);
    }
    expect(parseIepDraftDate('2028-02-29'), DateTime(2028, 2, 29));
  });
  IepDraftGoal goal({
    num baseline = 8,
    num target = 2,
    DateTime? start,
    DateTime? end,
  }) => IepDraftGoal(
    title: ' تقليل المقاطعة ',
    baseline: baseline,
    target: target,
    unit: ' مرات ',
    method: ' ملاحظة مباشرة ',
    start: start ?? DateTime(2026, 9, 1),
    end: end ?? DateTime(2027, 6, 1),
  );
  IepPlanDraft plan({
    int child = 8,
    int evaluation = 11,
    List<IepDraftGoal>? goals,
    DateTime? start,
    DateTime? end,
    DateTime? review,
  }) => IepPlanDraft(
    childId: child,
    evaluationId: evaluation,
    title: ' خطة ',
    start: start ?? DateTime(2026, 9, 1),
    end: end ?? DateTime(2027, 6, 1),
    reviewOn: review ?? DateTime(2027, 7, 1),
    goals: goals ?? [goal()],
  );
  test(
    'draft goals allow lower or equal targets without inventing progress',
    () {
      expect(goal().target, 2);
      expect(goal(target: 8).baseline, 8);
      expect(goal().title, 'تقليل المقاطعة');
      expect(() => goal(baseline: double.nan), throwsFormatException);
      expect(() => goal(target: double.infinity), throwsFormatException);
      expect(() => goal(end: DateTime(2026, 9, 1)), throwsFormatException);
    },
  );
  test(
    'draft requires a scoped reference, ordered period and contained goals',
    () {
      expect(() => plan(child: 0), throwsFormatException);
      expect(() => plan(evaluation: 0), throwsFormatException);
      expect(() => plan(goals: []), throwsFormatException);
      expect(() => plan(end: DateTime(2026, 8, 1)), throwsFormatException);
      expect(() => plan(review: DateTime(2026, 8, 1)), throwsFormatException);
      expect(
        () => plan(goals: [goal(start: DateTime(2026, 8, 31))]),
        throwsFormatException,
      );
      expect(
        () => plan(goals: [goal(end: DateTime(2027, 6, 2))]),
        throwsFormatException,
      );
      // A review after the plan end may be a renewal review.
      expect(plan().reviewOn, DateTime(2027, 7, 1));
    },
  );
  test(
    'prepared values are immutable snapshots, independent of editor lists',
    () {
      final goals = [goal()];
      final accommodations = [' وقت إضافي '];
      final draft = IepPlanDraft(
        childId: 8,
        evaluationId: 11,
        title: 'خطة',
        start: DateTime(2026, 9, 1),
        end: DateTime(2027, 6, 1),
        reviewOn: DateTime(2027, 1, 1),
        goals: goals,
        accommodations: accommodations,
      );
      goals.clear();
      accommodations.clear();
      expect(draft.goals, hasLength(1));
      expect(draft.accommodations, ['وقت إضافي']);
      expect(() => draft.goals.clear(), throwsUnsupportedError);
      expect(() => draft.accommodations.clear(), throwsUnsupportedError);
    },
  );
}
