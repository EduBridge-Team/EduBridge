import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/iep/iep_edit_source.dart';
import 'package:edubridge_app/model/iep/iep_plan_history.dart';
import 'package:edubridge_app/screens/iep/iep_draft_editor_screen.dart';
import 'curriculum_ui_support.dart';
import 'evaluation_history_fixture.dart';
import 'iep_draft_save_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('saved copy prefills without opening create save $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final plan = IepPlan.fromJson(newSavedPlan());
        final source = IepEditSource.capture(plan, plan.versions.single);
        final evaluations = EvaluationHistoryHttpFixture();
        await tester.pumpWidget(curriculumHost(IepDraftEditorScreen(
          childId: source.draft.childId, editSource: source,
          evaluationGateway: evaluations.repository,
        ), language));
        await tester.pumpAndSettle();
        final title = tester.widget<TextFormField>(find.byKey(const ValueKey('iep-input-title')));
        expect(title.initialValue, source.draft.title);
        expect(find.byKey(const ValueKey('iep-open-server-save')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
