import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/transfers/school_transfer.dart';
import 'package:edubridge_app/screens/school_transfers/school_transfers_screen.dart';
import 'package:edubridge_app/services/transfers/school_transfer_repository.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'curriculum_ui_support.dart';

class TransferGatewayFake implements SchoolTransferGateway {
  int creates = 0, decisions = 0;
  bool uncertain = false, done = false;
  Completer<void>? gate;
  @override
  Future<SchoolTransferDirectory> load() async =>
      SchoolTransferDirectory(enrollments: const [
        TransferChoice(10, 'Student A — Section A', childId: 30)
      ], schools: const [
        TransferChoice(9, 'Destination School')
      ], sections: const [
        TransferChoice(21, '2026 — Grade 2 — Section B')
      ], incoming: done ? [] : const [IncomingSchoolTransfer(40, 31, 9, 2)]);
  @override
  Future<int> create(int enrollment, int destination, String reason) async {
    creates++;
    expect(enrollment, 10);
    expect(destination, 9);
    await gate?.future;
    if (uncertain)
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    return 50;
  }

  @override
  Future<void> decide(IncomingSchoolTransfer request,
      {required bool accept, int? section, required String key}) async {
    decisions++;
    expect(request.id, 40);
    expect(section, 21);
    expect(key.length, 32);
    if (uncertain)
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    done = true;
  }
}

Future<void> chooseTransfer(
    WidgetTester tester, String key, String text) async {
  final field = find.byKey(ValueKey(key));
  if (field.evaluate().isEmpty) {
    await tester.scrollUntilVisible(field, 200,
        scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester
      .tap(find.descendant(of: field, matching: find.byType(OutlinedButton)));
  await tester.pumpAndSettle();
  final option = find.text(text).last;
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> tapTransfer(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets(
          'transfer request and destination decision $language $width large text',
          (tester) async {
        tester.view.physicalSize = Size(width, 1300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final f = TransferGatewayFake();
        await tester.pumpWidget(
            curriculumHost(SchoolTransfersScreen(gateway: f), language));
        await tester.pumpAndSettle();
        await chooseTransfer(
            tester, 'transfer-enrollment', 'Student A — Section A');
        await chooseTransfer(
            tester, 'transfer-destination', 'Destination School');
        await tapTransfer(tester, 'transfer-create');
        expect(f.creates, 0);
        await tapTransfer(tester, 'transfer-confirm');
        expect(f.creates, 1);
        await tester.scrollUntilVisible(find.textContaining('#50'), -200,
            scrollable: find.byType(Scrollable).first);
        expect(find.textContaining('#50'), findsOneWidget);
        await chooseTransfer(
            tester, 'transfer-section-40', '2026 — Grade 2 — Section B');
        await tapTransfer(tester, 'transfer-accept-40');
        expect(f.decisions, 0);
        await tapTransfer(tester, 'transfer-confirm');
        expect(f.decisions, 1);
        expect(find.byKey(const ValueKey('transfer-accept-40')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('uncertain creation cannot replay on refresh', (tester) async {
    final f = TransferGatewayFake()..uncertain = true;
    await tester
        .pumpWidget(curriculumHost(SchoolTransfersScreen(gateway: f), 'en'));
    await tester.pumpAndSettle();
    await chooseTransfer(
        tester, 'transfer-enrollment', 'Student A — Section A');
    await chooseTransfer(tester, 'transfer-destination', 'Destination School');
    await tapTransfer(tester, 'transfer-create');
    await tapTransfer(tester, 'transfer-confirm');
    expect(f.creates, 1);
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('transfer-enrollment'));
    final button = tester.widget<OutlinedButton>(
        find.descendant(of: field, matching: find.byType(OutlinedButton)));
    expect(button.onPressed, isNull);
    expect(f.creates, 1);
  });
  testWidgets('scope replacement discards unconfirmed transfer dialog',
      (tester) async {
    final first = TransferGatewayFake(), second = TransferGatewayFake();
    await tester.pumpWidget(
        curriculumHost(SchoolTransfersScreen(gateway: first), 'en'));
    await tester.pumpAndSettle();
    await chooseTransfer(
        tester, 'transfer-enrollment', 'Student A — Section A');
    await chooseTransfer(tester, 'transfer-destination', 'Destination School');
    await tapTransfer(tester, 'transfer-create');
    await tester.pumpWidget(
        curriculumHost(SchoolTransfersScreen(gateway: second), 'en'));
    await tester.pumpAndSettle();
    await tapTransfer(tester, 'transfer-confirm');
    expect(first.creates, 0);
    expect(second.creates, 0);
  });
}
