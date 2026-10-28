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
void main() {
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
