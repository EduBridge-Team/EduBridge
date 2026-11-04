import 'package:edubridge_app/model/iep/iep_draft.dart';
import 'package:edubridge_app/model/iep/iep_edit_source.dart';
import 'package:edubridge_app/screens/iep/iep_draft_editor_screen.dart';
import 'package:edubridge_app/services/iep/iep_completion_repository.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart';
import 'evaluation_history_fixture.dart';
import 'iep_draft_save_fixture.dart';
import 'iep_draft_screens_test.dart' show fillPlan, addDraftGoal, tapDraft;

class _CompletionGateway implements IepCompletionGateway {
  int optionReads = 0, writes = 0;
  bool canComplete = true;
  IepPlanDraft? received;

  @override
  Future<IepCompletionOptions> options() async {
    optionReads++;
    return IepCompletionOptions(8, 'rev-1', canComplete, {11});
  }

  @override
  Future<void> complete(IepPlanDraft draft,
      IepCompletionOptions expected, String key) async {
    expect(expected.canComplete, isTrue);
    expect(draft.childId, 8);
    expect(draft.evaluationId, 11);
    expect(key, matches(RegExp(r'^[a-f0-9]{32}$')));
    received = draft;
    writes++;
  }

  @override
  Future<void> completeExisting(IepEditSource source, IepPlanDraft draft,
      IepCompletionOptions expected, String key) async {
    throw StateError('The test creates a new plan, not a draft update');
  }
}

void main() {
  testWidgets('toolbar refresh replaces the old body button', (tester) async {
    final evaluations = EvaluationHistoryHttpFixture();
    await tester.pumpWidget(curriculumHost(
      IepDraftEditorScreen(childId: 8, evaluationGateway: evaluations.repository),
      'ar',
    ));
    await tester.pumpAndSettle();
    final toolbar = find.byType(BrandAppBar);
    expect(find.descendant(
      of: toolbar,
      matching: find.byKey(const ValueKey('iep-reload-evaluations')),
    ), findsOneWidget);
    expect(find.byKey(const ValueKey('iep-verify-draft')), findsNothing);
    expect(find.byKey(const ValueKey('iep-complete-plan')), findsOneWidget);
    expect(find.byKey(const ValueKey('iep-open-server-save')), findsOneWidget);
  });

  testWidgets('invalid Done and draft do not call either write service', (tester) async {
    final evaluations = EvaluationHistoryHttpFixture();
    final drafts = IepDraftSaveFixture();
    final completed = _CompletionGateway();
    await tester.pumpWidget(curriculumHost(IepDraftEditorScreen(
      childId: 8, evaluationGateway: evaluations.repository,
      saveGateway: drafts.repository, completionGateway: completed,
    ), 'en'));
    await tester.pumpAndSettle();
    await tapDraft(tester, 'iep-complete-plan');
    expect(completed.optionReads, 0);
    await tapDraft(tester, 'iep-open-server-save');
    expect(drafts.posts, isEmpty);
    expect(drafts.paths, isEmpty);
    expect(find.byKey(const ValueKey('iep-draft-goals-error')), findsOneWidget);
  });

  testWidgets('Done validates and completes without a second confirmation page',
      (tester) async {
    final evaluations = EvaluationHistoryHttpFixture();
    final completed = _CompletionGateway();
    await tester.pumpWidget(curriculumHost(Builder(builder: (context) {
      return Scaffold(body: TextButton(
        key: const ValueKey('open-editor'),
        onPressed: () => Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(builder: (_) => IepDraftEditorScreen(
            childId: 8,
            evaluationGateway: evaluations.repository,
            completionGateway: completed,
          )),
        ),
        child: const Text('Open editor'),
      ));
    }), 'en'));
    await tester.tap(find.byKey(const ValueKey('open-editor')));
    await tester.pumpAndSettle();
    await fillPlan(tester);
    await addDraftGoal(tester);
    await tapDraft(tester, 'iep-complete-plan');
    expect(completed.optionReads, 1);
    expect(completed.writes, 1);
    expect(completed.received?.title, 'خطة محمود الأصلية');
    expect(find.byType(IepDraftEditorScreen), findsNothing);
    expect(find.byKey(const ValueKey('open-editor')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('server denial never reports Done or leaves the editor',
      (tester) async {
    final evaluations = EvaluationHistoryHttpFixture();
    final completed = _CompletionGateway()..canComplete = false;
    await tester.pumpWidget(curriculumHost(IepDraftEditorScreen(
      childId: 8, evaluationGateway: evaluations.repository,
      completionGateway: completed,
    ), 'en'));
    await tester.pumpAndSettle();
    await fillPlan(tester);
    await addDraftGoal(tester);
    await tapDraft(tester, 'iep-complete-plan');
    expect(completed.writes, 0);
    expect(find.byKey(const ValueKey('iep-submit-error')), findsOneWidget);
    expect(find.byType(IepDraftEditorScreen), findsOneWidget);
  });
}
