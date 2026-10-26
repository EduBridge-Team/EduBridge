import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/evaluation_history/evaluation_history_screen.dart';
import 'package:edubridge_app/screens/evaluation_history/evaluation_record_screen.dart';
import 'package:edubridge_app/screens/iep/iep_history_screen.dart';
import 'package:edubridge_app/screens/iep/iep_plan_card.dart';
import 'package:edubridge_app/screens/iep/iep_version_screen.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart' show curriculumHost, resumeCurriculum;
import 'evaluation_history_fixture.dart';
import 'iep_http_fixture.dart';

Future<void> revealIep(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    final scroll = find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first;
    tester.state<ScrollableState>(scroll).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(target, 250, scrollable: scroll);
  }
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> tapIep(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await revealIep(tester, target);
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('IEP versions/goals/reference in $language at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = IepHttpFixture();
        final evaluations = EvaluationHistoryHttpFixture();
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await tester.pumpWidget(
          curriculumHost(
            IepHistoryScreen(
              childId: 8,
              childName: 'محمود',
              gateway: fixture.repository,
              evaluationGateway: evaluations.repository,
            ),
            language,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BrandAppBar), findsOneWidget);
        final plan = tester.widget<IepPlanCard>(find.byType(IepPlanCard)).plan;
        expect(plan.currentApprovedId, 101);
        expect(plan.versions.first.id, 102);
        await tapIep(tester, 'iep-version-102');
        expect(find.byType(IepVersionScreen), findsOneWidget);
        expect(find.text(strings.iepDraft), findsOneWidget);
        expect(find.text(strings.iepCurrentApproved), findsNothing);
        final goal = find.byKey(const ValueKey('iep-goal-501'));
        await revealIep(tester, goal);
        expect(find.text(iepGoalText), findsOneWidget);
        expect(
          find.text('${strings.iepBaseline}: 2 كلمات في المحاولة'),
          findsOneWidget,
        );
        expect(
          find.text('${strings.iepTarget}: 8 كلمات في المحاولة'),
          findsOneWidget,
        );
        await tapIep(tester, 'iep-evaluation-reference');
        expect(find.byType(EvaluationRecordScreen), findsOneWidget);
        expect(
          tester
              .widget<EvaluationRecordScreen>(
                find.byType(EvaluationRecordScreen),
              )
              .record
              .id,
          11,
        );
        expect(evaluations.paths, ['/evaluations/child/8']);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tapIep(tester, 'iep-version-101');
        expect(find.text(strings.iepApproved), findsOneWidget);
        expect(find.text(strings.iepCurrentApproved), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        fixture.payload = {'child_id': 8, 'plans': []};
        await resumeCurriculum(tester);
        expect(find.text(strings.iepEmpty), findsOneWidget);
        fixture.status = 404;
        await resumeCurriculum(tester);
        expect(find.text(strings.iepUnavailable), findsOneWidget);
        expect(find.text(strings.iepEmpty), findsNothing);
        fixture.status = 200;
        fixture.payload = iepHistoryJson();
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();
        expect(find.byType(IepPlanCard), findsOneWidget);
        final scroll = find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first;
        tester.state<ScrollableState>(scroll).position.jumpTo(0);
        await tester.pump();
        await tester.drag(find.byType(ListView), const Offset(0, 350));
        await tester.pumpAndSettle();
        expect(fixture.reads.length, 5);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets(
    'evaluation history opens separate IEP history without inventing a version',
    (tester) async {
      final plans = IepHttpFixture();
      final evaluations = EvaluationHistoryHttpFixture();
      await tester.pumpWidget(
        curriculumHost(
          EvaluationHistoryScreen(
            childId: 8,
            childName: 'محمود',
            gateway: evaluations.repository,
            iepGateway: plans.repository,
          ),
          'en',
        ),
      );
      await tester.pumpAndSettle();
      await tapIep(tester, 'open-child-iep');
      expect(find.byType(IepHistoryScreen), findsOneWidget);
      expect(plans.reads, ['/children/8/iep-plans']);
    },
  );
  testWidgets(
    'returned version shows reason; missing reference evaluation is an error',
    (tester) async {
      final fixture = IepHttpFixture()
        ..payload = {
          'child_id': 8,
          'plans': [
            {
              ...iepPlanJson(),
              'versions': [
                iepVersionJson(id: 101, number: 1, status: 'approved'),
                iepVersionJson(id: 103, number: 3, status: 'returned'),
              ],
            },
          ],
        };
      final evaluations = EvaluationHistoryHttpFixture()..records = [];
      await tester.pumpWidget(
        curriculumHost(
          IepHistoryScreen(
            childId: 8,
            gateway: fixture.repository,
            evaluationGateway: evaluations.repository,
          ),
          'en',
        ),
      );
      await tester.pumpAndSettle();
      await tapIep(tester, 'iep-version-103');
      final reason = find.byKey(const ValueKey('iep-return-reason'));
      await revealIep(tester, reason);
      expect(
        tester.widget<SelectableText>(reason).data,
        contains('أضف وسيلة قياس واضحة'),
      );
      await tapIep(tester, 'iep-evaluation-reference');
      expect(find.byType(EvaluationRecordScreen), findsNothing);
      final strings = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        find.text(strings.evaluationHistoryInvalidResponse),
        findsOneWidget,
      );
      expect(find.byType(IepVersionScreen), findsOneWidget);
    },
  );
}
