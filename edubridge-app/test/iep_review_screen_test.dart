import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/iep/iep_plan_history.dart';
import 'package:edubridge_app/model/iep/iep_review.dart';
import 'package:edubridge_app/screens/iep/iep_review_screen.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/iep/iep_review_repository.dart';
import 'curriculum_ui_support.dart';
import 'iep_draft_save_fixture.dart';

class ReviewFixture implements IepReviewGateway {
  bool missing = false;
  int writes = 0;
  @override
  Future<IepReviewOptions> load() async {
    if (missing) throw const EnrollmentApiException(EnrollmentFailure.unavailable);
    return IepReviewOptions('r1', {IepReviewAction.returnForChanges, IepReviewAction.approve});
  }
  @override
  Future<void> act(IepReviewAction action, IepReviewOptions expected, String key, {String reason = ''}) async {
    writes++; throw const EnrollmentApiException(EnrollmentFailure.uncertain);
  }
}
void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('review capability failure never exposes actions $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1600); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final raw = newSavedPlan(); (raw['versions'] as List).single['status'] = 'submitted';
        final plan = IepPlan.fromJson(raw);
        final gateway = ReviewFixture()..missing = true;
        await tester.pumpWidget(curriculumHost(IepReviewScreen(
          source: IepReviewSource(plan, plan.versions.single), gateway: gateway), language));
        await tester.pumpAndSettle();
        expect(find.byType(FilledButton), findsNothing);
        await resumeCurriculum(tester);
        expect(gateway.writes, 0); expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('uncertain review locks writes across read refresh', (tester) async {
    final raw = newSavedPlan(); (raw['versions'] as List).single['status'] = 'submitted';
    final plan = IepPlan.fromJson(raw), gateway = ReviewFixture();
    await tester.pumpWidget(curriculumHost(IepReviewScreen(
      source: IepReviewSource(plan, plan.versions.single), gateway: gateway), 'en'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('iep-review-return')));
    await tester.tap(find.byKey(const ValueKey('iep-review-return'))); await tester.pumpAndSettle();
    expect(gateway.writes, 0); expect(find.byType(AlertDialog), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('iep-review-approve')));
    await tester.tap(find.byKey(const ValueKey('iep-review-approve'))); await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('iep-review-confirm'))); await tester.pumpAndSettle();
    expect(gateway.writes, 1);
    await resumeCurriculum(tester);
    for (final button in tester.widgetList<FilledButton>(find.byType(FilledButton))) {
      expect(button.onPressed, isNull);
    }
    expect(gateway.writes, 1); expect(tester.takeException(), isNull);
  });
}
