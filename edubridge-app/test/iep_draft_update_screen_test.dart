import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/iep/iep_draft.dart';
import 'package:edubridge_app/model/iep/iep_edit_source.dart';
import 'package:edubridge_app/model/iep/iep_plan_history.dart';
import 'package:edubridge_app/screens/iep/iep_draft_update_screen.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/iep/iep_draft_update_repository.dart';
import 'curriculum_ui_support.dart';
import 'iep_draft_save_fixture.dart';

class MissingUpdateService implements IepDraftUpdateGateway {
  int writes = 0;
  @override
  Future<IepDraftEditOptions> load() async => throw const EnrollmentApiException(EnrollmentFailure.unavailable);
  @override
  Future<void> update(IepPlanDraft draft, IepDraftEditOptions options, String key) async { writes++; }
}

class ControlledUpdateService implements IepDraftUpdateGateway {
  ControlledUpdateService(this.evaluationId, {this.pending});
  final int evaluationId;
  final Completer<void>? pending;
  int writes = 0;
  @override
  Future<IepDraftEditOptions> load() async => IepDraftEditOptions('revision-1', {evaluationId});
  @override
  Future<void> update(IepPlanDraft draft, IepDraftEditOptions options, String key) async {
    writes++;
    await pending?.future;
  }
}

void main() {

  testWidgets('old IEP update cannot confirm after gateway replacement', (tester) async {
    final plan = IepPlan.fromJson(newSavedPlan());
    final source = IepEditSource.capture(plan, plan.versions.single);
    final pending = Completer<void>();
    final first = ControlledUpdateService(source.draft.evaluationId, pending: pending);
    final next = ControlledUpdateService(source.draft.evaluationId);
    // Use the evaluation actually carried by this saved plan.
    final options = IepDraftEditOptions('revision-1', {source.draft.evaluationId});
    expect(options.evaluationIds.contains(source.draft.evaluationId), isTrue);
    await tester.pumpWidget(curriculumHost(IepDraftUpdateScreen(
      source: source, draft: source.draft, gateway: first), 'en'));
    await tester.pumpAndSettle();
    // A capability gateway must list the source evaluation before editing.
    expect(find.byKey(const ValueKey('iep-update-save')), findsOneWidget);
    await tester.pumpWidget(curriculumHost(IepDraftUpdateScreen(
      source: source, draft: source.draft, gateway: next), 'en'));
    await tester.pumpAndSettle();
    pending.complete();
    await tester.pumpAndSettle();
    expect(first.writes, 0);
    expect(next.writes, 0);
    expect(find.textContaining('Draft changes confirmed saved'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('missing capability disables update $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1600); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final plan = IepPlan.fromJson(newSavedPlan());
        final source = IepEditSource.capture(plan, plan.versions.single);
        final gateway = MissingUpdateService();
        await tester.pumpWidget(curriculumHost(IepDraftUpdateScreen(source: source,
          draft: source.draft, gateway: gateway), language));
        await tester.pumpAndSettle();
        final button = tester.widget<FilledButton>(find.byKey(const ValueKey('iep-update-save')));
        expect(button.onPressed, isNull);
        await resumeCurriculum(tester);
        expect(gateway.writes, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
