import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/schools/academic_catalog.dart';
import 'package:edubridge_app/services/schools/academic_repository.dart';
import 'package:edubridge_app/screens/enrollment/school_annual_promotion_screen.dart';
import 'curriculum_ui_support.dart';

class _ReadOnlyAcademicGateway implements AcademicGateway {
  int reads = 0, writes = 0;
  @override
  Future<AcademicCatalog> load() async {
    reads++;
    return AcademicCatalog.fromJson({
      'school': {'id': 5, 'name': 'مدرسة الأمل'},
      'academic_years': [
        {'id': 10, 'school_id': 5, 'name': '2026-2027',
          'starts_on': '2026-09-01', 'ends_on': '2027-06-30', 'is_current': true},
        {'id': 11, 'school_id': 5, 'name': '2027-2028',
          'starts_on': '2027-09-01', 'ends_on': '2028-06-30', 'is_current': false},
      ],
      'grades': <Object>[], 'sections': <Object>[],
      'academic_terms': <Object>[], 'subjects': <Object>[],
    });
  }
  @override
  Future<void> create(int schoolId, AcademicDraft draft) async { writes++; }
}

void main() {
  for (final language in ['ar', 'en']) {
    testWidgets('school account promotion picks years but never approves $language', (tester) async {
      final gateway = _ReadOnlyAcademicGateway();
      await tester.pumpWidget(curriculumHost(
        SchoolAnnualPromotionScreen(gateway: gateway), language));
      await tester.pumpAndSettle();
      expect(find.text('مدرسة الأمل'), findsOneWidget);
      final approve = tester.widget<FilledButton>(
        find.byKey(const ValueKey('promotion-approve')));
      expect(approve.onPressed, isNull);
      expect(gateway.reads, 1);
      expect(gateway.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
