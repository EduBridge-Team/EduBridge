import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/iep/iep_draft_editor_screen.dart';
import 'package:edubridge_app/screens/iep/iep_draft_goal_card.dart';
import 'package:edubridge_app/screens/iep/iep_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart' show curriculumHost;
import 'evaluation_history_fixture.dart';
import 'iep_draft_save_fixture.dart';
import 'iep_draft_screens_test.dart' show fillPlan, addDraftGoal, tapDraft, revealDraft;

void main() {
  testWidgets('confirmed draft returns to fresh saved history without another create', (tester) async {
    final f = IepDraftSaveFixture();
    f.plan['title'] = 'خطة محمود الأصلية';
    final version = (f.plan['versions'] as List).single as Map<String, dynamic>;
    version['summary'] = '';
    version['ends_on'] = '2027-06-01';
    version['accommodations'] = <String>[];
    final goal = (version['goals'] as List).single as Map<String, dynamic>;
    goal.addAll({'title': 'تقليل المقاطعة في الجلسة', 'baseline': 8, 'target': 2.5,
      'unit': 'مرات في الجلسة', 'measurement_method': 'ملاحظة مباشرة في كل جلسة',
      'responsible_name': 'المختص'});
    final evaluations = EvaluationHistoryHttpFixture();
    await tester.pumpWidget(curriculumHost(IepHistoryScreen(childId: 8,
      gateway: f.historyRepository, saveGateway: f.repository,
      evaluationGateway: evaluations.repository), 'en'));
    await tester.pumpAndSettle();
    await tapDraft(tester, 'iep-prepare-draft');
    await fillPlan(tester);
    await addDraftGoal(tester);
    await tapDraft(tester, 'iep-verify-draft');
    await tapDraft(tester, 'iep-open-server-save');
    await tapDraft(tester, 'iep-save-to-server');
    await tapDraft(tester, 'iep-confirm-save');
    expect(find.byKey(const ValueKey('iep-server-saved')), findsOneWidget);
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final historyButton = find.widgetWithText(FilledButton, l.iepTitle);
    await revealDraft(tester, historyButton);
    await tester.tap(historyButton);
    await tester.pumpAndSettle();
    expect(find.byType(IepDraftEditorScreen), findsNothing);
    expect(find.byType(IepHistoryScreen), findsOneWidget);
    expect(f.posts, hasLength(1));
    expect(f.paths.where((p) => p == '/children/8/iep-plans'), hasLength(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable save preserves the prepared editor and goals', (tester) async {
    final f = IepDraftSaveFixture()..optionsStatus = 404;
    final evaluations = EvaluationHistoryHttpFixture();
    await tester.pumpWidget(curriculumHost(IepDraftEditorScreen(childId: 8,
      saveGateway: f.repository, evaluationGateway: evaluations.repository), 'en'));
    await tester.pumpAndSettle();
    await fillPlan(tester);
    await addDraftGoal(tester);
    await tapDraft(tester, 'iep-verify-draft');
    await tapDraft(tester, 'iep-open-server-save');
    expect(find.byKey(const ValueKey('iep-save-error')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(IepDraftEditorScreen), findsOneWidget);
    expect(find.byType(IepDraftGoalCard), findsOneWidget);
    expect(tester.widget<TextFormField>(find.byKey(const ValueKey('iep-input-title'))).controller?.text ??
      tester.widget<TextFormField>(find.byKey(const ValueKey('iep-input-title'))).initialValue, 'خطة محمود الأصلية');
    expect(f.posts, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
