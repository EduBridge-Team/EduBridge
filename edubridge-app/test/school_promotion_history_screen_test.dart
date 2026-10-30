import 'package:edubridge_app/screens/enrollment/school_promotion_history_screen.dart';
import 'package:edubridge_app/model/schools/promotion_roster.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/school_promotion_operation_repository.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'curriculum_ui_support.dart';

class _FakeHistoryGateway implements SchoolPromotionOperationGateway {
  bool fail = false;
  int reads = 0;
  @override
  Future<List<SchoolPromotionReceipt>> history({required int yearId, required int schoolId}) async {
    reads++;
    if (fail) throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    if (yearId != 10 || schoolId != 5) throw StateError('Unexpected school scope');
    return const [SchoolPromotionReceipt(operationId: 'op_1', schoolId: 5,
      sourceYearId: 10, targetYearId: 11, status: 'completed',
      promoted: 3, repeating: 0, transferred: 1)];
  }
  @override
  Future<SchoolPromotionServerPreview> preview(PromotionDraft draft) =>
    throw UnimplementedError();
  @override
  Future<SchoolPromotionReceipt> approve(PromotionDraft draft,
    SchoolPromotionServerPreview preview, String key) => throw UnimplementedError();
  @override
  Future<SchoolPromotionReceipt> operation(String id, {required int schoolId}) =>
    throw UnimplementedError();
}

void main() {
  for (final language in ['ar', 'en']) {
    testWidgets('history shows localized server status and zero counts $language', (tester) async {
      final gateway = _FakeHistoryGateway();
      await tester.pumpWidget(curriculumHost(
        SchoolPromotionHistoryScreen(schoolId: 5, yearId: 10, gateway: gateway), language));
      await tester.pumpAndSettle();
      expect(find.byType(BrandAppBar), findsOneWidget);
      expect(find.textContaining('op_1'), findsOneWidget);
      expect(find.textContaining(language == 'ar' ? 'مكتملة' : 'Completed'), findsOneWidget);
      expect(find.textContaining(language == 'ar' ? 'معيد: 0' : 'Repeating: 0'), findsOneWidget);
      expect(gateway.reads, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('history access denied has retry and no stale receipts $language', (tester) async {
      final gateway = _FakeHistoryGateway()..fail = true;
      await tester.pumpWidget(curriculumHost(
        SchoolPromotionHistoryScreen(schoolId: 5, yearId: 10, gateway: gateway), language));
      await tester.pumpAndSettle();
      expect(find.textContaining('op_1'), findsNothing);
      final retry = find.byKey(const ValueKey('promotion-history-retry'));
      expect(retry, findsOneWidget);
      gateway.fail = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.textContaining('op_1'), findsOneWidget);
      expect(gateway.reads, 2);
      expect(tester.takeException(), isNull);
    });
  }
}
