import 'package:edubridge_app/model/schools/promotion_roster.dart';
import 'package:edubridge_app/screens/enrollment/school_promotion_review_screen.dart';
import 'package:edubridge_app/services/schools/school_promotion_roster_repository.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'curriculum_ui_support.dart';

class _RosterGateway implements SchoolPromotionRosterGateway {
  int reads = 0;
  @override
  Future<PromotionRoster> load({required int sourceYearId, required int targetYearId}) async {
    reads++;
    return PromotionRoster.fromJson({
      'school_id': 5, 'source_year_id': 10, 'target_year_id': 11,
      'complete': true, 'revision': 'rev1',
      'students': [
        {'enrollment_id': 101, 'child_id': 201, 'child_name': 'Sara',
          'source_grade_id': 20, 'source_grade_position': 2, 'source_section_id': 30},
      ],
      'target_sections': [
        {'id': 31, 'grade_id': 21, 'grade_position': 3, 'name': 'Third A', 'capacity': 3, 'occupied': 0},
      ],
    }, schoolId: 5, sourceYearId: sourceYearId, targetYearId: targetYearId);
  }
}

void main() {
  for (final language in ['ar', 'en']) {
    testWidgets('promotion review shows guarded local preview $language', (tester) async {
      final gateway = _RosterGateway();
      await tester.pumpWidget(curriculumHost(
        SchoolPromotionReviewScreen(sourceYearId: 10, targetYearId: 11,
          gateway: gateway), language));
      await tester.pumpAndSettle();
      expect(find.byType(BrandAppBar), findsOneWidget);
      expect(find.text('Sara'), findsOneWidget);
      final outcome = find.byKey(const ValueKey('promotion-outcome-101'));
      await tester.scrollUntilVisible(outcome, 100,
        scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(outcome);
      await tester.pumpAndSettle();
      await tester.tap(find.text(language == 'ar' ? 'ناجح' : 'Promoted').last);
      await tester.pumpAndSettle();
      final destination = find.byKey(
        const ValueKey('promotion-destination-101-promoted'));
      await tester.scrollUntilVisible(destination, 120,
        scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(destination);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Third A').last);
      await tester.pumpAndSettle();
      final preview = find.byKey(const ValueKey('promotion-local-preview'));
      await tester.scrollUntilVisible(preview, 160,
        scrollable: find.byType(Scrollable).first);
      expect(tester.widget<FilledButton>(preview).onPressed, isNotNull);
      expect(tester.widget<FilledButton>(
        find.byKey(const ValueKey('promotion-approve'))).onPressed, isNull);
      await tester.tap(preview);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining(language == 'ar' ? 'لم يُنقل' : 'No students have'),
        findsOneWidget);
      expect(gateway.reads, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
