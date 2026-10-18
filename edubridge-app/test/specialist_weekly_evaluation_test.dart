import 'package:edubridge_app/model/specialist_weekly_evaluation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads existing API sections and preserves multiline recommendations', () {
    final result = SpecialistWeeklyEvaluation.fromNotes(
      'تحسن في القراءة\nالتوصيات: تدريب يومي\nومراجعة الكلمات\nملاءمة الخطة: مناسبة\nتقييم التفاعل: 3/5');
    expect(result.notes, 'تحسن في القراءة');
    expect(result.recommendations, 'تدريب يومي\nومراجعة الكلمات');
    expect(result.suitability, 'مناسبة');
    expect(result.interaction, '3/5');
  });
  test('missing evaluation does not invent plan suitability or a rating', () {
    final result = SpecialistWeeklyEvaluation.fromNotes(null);
    expect(result.suitability, isNull);
    expect(result.interaction, isNull);
    expect(result.notes, isEmpty);
  });
  test('legacy prose is retained and plan changes are distinct', () {
    final legacy = SpecialistWeeklyEvaluation.fromNotes('ملاحظات قديمة\nسطر ثان');
    expect(legacy.notes, 'ملاحظات قديمة\nسطر ثان');
    final result = SpecialistWeeklyEvaluation.fromNotes(
      'ملاحظة\nملاءمة الخطة: تحتاج تعديلاً\nتقييم الخطة: تبسيط الأنشطة\nتقييم التفاعل: 2/5');
    expect(result.planChanges, 'تبسيط الأنشطة');
    expect(result.suitability, 'تحتاج تعديلاً');
    expect(result.interaction, '2/5');
  });
}
