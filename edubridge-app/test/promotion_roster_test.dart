import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/schools/promotion_roster.dart';

Map<String, dynamic> rosterJson() => {
  'school_id': 5, 'source_year_id': 10, 'target_year_id': 11,
  'complete': true, 'revision': 'r-10',
  'students': [
    {'enrollment_id': 100, 'child_id': 200, 'child_name': 'Student',
     'source_grade_id': 20, 'source_section_id': 30},
  ],
  'target_sections': [
    {'id': 31, 'grade_id': 21, 'name': 'Third A', 'capacity': 2, 'occupied': 0},
    {'id': 32, 'grade_id': 20, 'name': 'Second A', 'capacity': 1, 'occupied': 0},
  ],
};

void main() {
  test('roster rejects a foreign school and incomplete pagination', () {
    expect(() => PromotionRoster.fromJson(rosterJson(), schoolId: 9,
      sourceYearId: 10, targetYearId: 11), throwsFormatException);
    expect(() => PromotionRoster.fromJson({...rosterJson(), 'complete': false},
      schoolId: 5, sourceYearId: 10, targetYearId: 11), throwsFormatException);
  });
  test('manual choices require a complete explicit decision', () {
    final roster = PromotionRoster.fromJson(rosterJson(), schoolId: 5,
      sourceYearId: 10, targetYearId: 11);
    expect(PromotionDraft(roster, {}).ready, isFalse);
    final passed = PromotionDraft(roster, {
      100: const PromotionSelection(100, PromotionOutcome.promoted, 31),
    });
    expect(passed.ready, isTrue);
    expect((passed.previewJson()['decisions'] as List).single['decision'], 'promoted');
    expect(PromotionDraft(roster, {
      100: const PromotionSelection(100, PromotionOutcome.repeating, 32),
    }).ready, isTrue);
    expect(PromotionDraft(roster, {
      100: const PromotionSelection(100, PromotionOutcome.transferred, null, targetSchoolId: 8),
    }).ready, isTrue);
    expect(PromotionDraft(roster, {
      100: const PromotionSelection(100, PromotionOutcome.promoted, 32),
    }).ready, isFalse);
    expect(PromotionDraft(roster, {
      100: const PromotionSelection(100, PromotionOutcome.transferred, null),
    }).ready, isFalse);
  });
  test('full destinations and duplicate students are rejected', () {
    final full = rosterJson();
    (full['target_sections'] as List)[0]['occupied'] = 2;
    final roster = PromotionRoster.fromJson(full, schoolId: 5,
      sourceYearId: 10, targetYearId: 11);
    expect(PromotionDraft(roster, {
      100: const PromotionSelection(100, PromotionOutcome.promoted, 31),
    }).ready, isFalse);
    final duplicate = rosterJson();
    (duplicate['students'] as List).add(Map<String, Object>.from(
      (duplicate['students'] as List).single as Map));
    expect(() => PromotionRoster.fromJson(duplicate, schoolId: 5,
      sourceYearId: 10, targetYearId: 11), throwsFormatException);
  });
}
