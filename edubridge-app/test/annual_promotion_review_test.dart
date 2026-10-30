import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/schools/annual_promotion_review.dart';
import 'institution_enrollment_history_fixture.dart';

void main() {
  test('annual promotion is a deliberate per-student preview, never an automatic write', () async {
    final fixture = InstitutionHistoryFixture();
    (fixture.academic.data['academic_years'] as List).add({
      'id': 11, 'school_id': 5, 'name': '2027–2028',
      'starts_on': '2027-09-01', 'ends_on': '2028-06-30', 'is_current': false,
    });
    (fixture.academic.data['grades'] as List).add({
      'id': 21, 'school_id': 5, 'name': 'الصف الثالث',
    });
    (fixture.academic.data['sections'] as List).addAll([
      {'id': 31, 'academic_year_id': 11, 'grade_id': 21,
       'name': 'الثالث أ', 'capacity': 2, 'homeroom_teacher_name': null},
      {'id': 32, 'academic_year_id': 11, 'grade_id': 20,
       'name': 'الثاني أ', 'capacity': 2, 'homeroom_teacher_name': null},
    ]);
    final history = await fixture.repository.load();
    AnnualPromotionReview review(AnnualPromotionDecision decision, int? targetSection) =>
        AnnualPromotionReview(history: history, sourceYearId: 10, targetYearId: 11,
          choices: [AnnualPromotionChoice(
            enrollmentId: 2, decision: decision, targetSectionId: targetSection)]);
    expect(review(AnnualPromotionDecision.promoted, 31).ready, isTrue);
    expect(review(AnnualPromotionDecision.repeating, 32).ready, isTrue);
    expect(review(AnnualPromotionDecision.transferred, null).ready, isTrue);
    expect(review(AnnualPromotionDecision.promoted, 32).ready, isFalse);
    expect(review(AnnualPromotionDecision.repeating, 31).ready, isFalse);
    expect(review(AnnualPromotionDecision.transferred, 31).ready, isFalse);
    expect(AnnualPromotionReview(history: history, sourceYearId: 10, targetYearId: 11,
      choices: const []).ready, isFalse);
    expect(fixture.writes, isEmpty);
    expect(fixture.patches, isEmpty);
  });
}
