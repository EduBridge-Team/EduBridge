import 'package:edubridge_app/screens/enrollment/school_promotion_approval_screen.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/school_promotion_operation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'school_account_form_test.dart' show host;
import 'school_promotion_operation_repository_test.dart' show draft;

class ApprovalGateway implements SchoolPromotionOperationGateway {
  int writes = 0, recoveries = 0;
  bool uncertain = false;
  String? key;
  @override
  Future<SchoolPromotionServerPreview> preview(dynamic value) async =>
      const SchoolPromotionServerPreview('token', 'rev-1', 5, 10, 11, true);
  SchoolPromotionReceipt receipt(String id) => SchoolPromotionReceipt(
    operationId: id, schoolId: 5, sourceYearId: 10, targetYearId: 11,
    status: 'completed', promoted: 1, repeating: 0, transferred: 0);
  @override
  Future<SchoolPromotionReceipt> approve(dynamic value,
      SchoolPromotionServerPreview preview, String idempotencyKey) async {
    writes++; key = idempotencyKey;
    if (uncertain) throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    return receipt(idempotencyKey);
  }
  @override
  Future<SchoolPromotionReceipt> operation(String id, {required int schoolId}) async {
    recoveries++; return receipt(id);
  }
  @override
  Future<List<SchoolPromotionReceipt>> history({required int yearId, required int schoolId}) async => [];
}

void main() {
  for (final language in ['ar', 'en']) {
    testWidgets('server approval requires acknowledgement and recovers without replay in $language', (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gateway = ApprovalGateway()..uncertain = true;
      await tester.pumpWidget(host(SchoolPromotionApprovalScreen(draft: draft(), gateway: gateway), language));
      await tester.pumpAndSettle();
      final approve = find.byKey(const ValueKey('promotion-server-approve'));
      expect(tester.widget<FilledButton>(approve).onPressed, isNull);
      final confirm = find.byKey(const ValueKey('promotion-confirm-review'));
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      await tester.ensureVisible(approve);
      await tester.tap(approve);
      await tester.pumpAndSettle();
      expect(gateway.writes, 1);
      expect(gateway.key, matches(RegExp(r'^[a-zA-Z0-9_-]{32}$')));
      expect(approve, findsNothing);
      final recover = find.text(language == 'en' ? 'Check outcome' : 'التحقق من النتيجة');
      await tester.ensureVisible(recover);
      await tester.tap(recover);
      await tester.pumpAndSettle();
      expect(gateway.recoveries, 1);
      expect(gateway.writes, 1);
      expect(find.byKey(const ValueKey('promotion-server-success')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
