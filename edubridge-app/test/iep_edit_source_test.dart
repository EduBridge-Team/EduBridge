import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/iep/iep_edit_source.dart';
import 'package:edubridge_app/model/iep/iep_plan_history.dart';
import 'iep_draft_save_fixture.dart';

void main() {
  test('baseline round trip preserves draft and detects content changes', () {
    final plan = IepPlan.fromJson(newSavedPlan());
    final source = IepEditSource.capture(plan, plan.versions.single);
    final same = IepPlan.fromJson(newSavedPlan());
    expect(source.matches(same, same.versions.single), isTrue);
    expect(source.draft.title, plan.title);
    expect(source.draft.goals.single.title, plan.versions.single.goals.single.title);
    final changed = newSavedPlan()..['title'] = 'Changed title';
    final other = IepPlan.fromJson(changed);
    expect(source.matches(other, other.versions.single), isFalse);
  });
  test('closed and submitted versions cannot become edit baselines', () {
    for (final closed in [true, false]) {
      final json = newSavedPlan();
      if (closed) {
        json['is_closed'] = true;
      } else {
        (json['versions'] as List).single['status'] = 'submitted';
      }
      final plan = IepPlan.fromJson(json);
      expect(() => IepEditSource.capture(plan, plan.versions.single), throwsFormatException);
    }
  });
  test('a foreign version cannot be attached to an authorized plan', () {
    final plan = IepPlan.fromJson(newSavedPlan());
    final foreign = IepPlan.fromJson(newSavedPlan());
    expect(() => IepEditSource.capture(plan, foreign.versions.single), throwsFormatException);
  });
}
