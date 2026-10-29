import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/iep/iep_plan_history.dart';
import 'package:edubridge_app/screens/iep/iep_goal_evidence_screen.dart';
import 'package:edubridge_app/screens/iep/iep_version_screen.dart';
import 'curriculum_ui_support.dart';
import 'iep_draft_save_fixture.dart';
import 'iep_goal_evidence_fixture.dart';
import 'evaluation_history_fixture.dart';

Future<void> revealEvidence(WidgetTester tester, Finder target) async {
  final scroll = find.descendant(of: find.byType(ListView).first,
      matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(target, 250, scrollable: scroll);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('goal history full labels and measurements at 2x $locale $width', (tester) async {
        tester.view.physicalSize = Size(width, 2400); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final source = evidenceSource(), f = EvidenceFixture(evidenceSource());
        await tester.pumpWidget(curriculumHost(IepGoalEvidenceScreen(source: source, gateway: f.repository), locale));
        await tester.pumpAndSettle();
        final target = find.byKey(const ValueKey('iep-evidence-2'));
        await revealEvidence(tester, target);
        expect(target, findsOneWidget);
        await revealEvidence(tester, find.byKey(const ValueKey('iep-evidence-measurement-2')));
        await tester.pumpAndSettle();
        expect(find.textContaining('0 ${source.goal.unit}'), findsOneWidget);
        await revealEvidence(tester, find.byKey(const ValueKey('iep-evidence-measurement-1')));
        expect(tester.widget<Text>(find.byKey(const ValueKey('iep-evidence-measurement-1'))).data,
            endsWith(': —'));
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('refresh hides evidence immediately and denial removes it', (tester) async {
    final source = evidenceSource(), f = EvidenceFixture(evidenceSource());
    await tester.pumpWidget(curriculumHost(IepGoalEvidenceScreen(source: source, gateway: f.repository), 'en'));
    await tester.pumpAndSettle();
    await revealEvidence(tester, find.byKey(const ValueKey('iep-evidence-2')));
    f.pending = Completer<void>(); f.status = 403;
    await tester.tap(find.byIcon(Icons.refresh)); await tester.pump();
    expect(find.byKey(const ValueKey('iep-evidence-2')), findsNothing);
    f.pending!.complete(); await tester.pumpAndSettle();
    await revealEvidence(tester, find.byKey(const ValueKey('iep-evidence-error')));
    expect(find.byKey(const ValueKey('iep-evidence-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('iep-evidence-2')), findsNothing);
    expect(f.paths, hasLength(2));
  });
  testWidgets('source replacement ignores old pending response and resume reloads', (tester) async {
    final source = evidenceSource(), old = EvidenceFixture(evidenceSource())..pending = Completer<void>();
    await tester.pumpWidget(curriculumHost(IepGoalEvidenceScreen(source: source, gateway: old.repository), 'en'));
    await tester.pump();
    final next = EvidenceFixture(source)..status = 404;
    await tester.pumpWidget(curriculumHost(IepGoalEvidenceScreen(source: source, gateway: next.repository), 'en'));
    await tester.pumpAndSettle();
    old.pending!.complete(); await tester.pumpAndSettle();
    await revealEvidence(tester, find.byKey(const ValueKey('iep-evidence-error')));
    expect(find.byKey(const ValueKey('iep-evidence-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('iep-evidence-2')), findsNothing);
    next.status = 200; next.data['evidence'] = <Object>[];
    await resumeCurriculum(tester);
    await revealEvidence(tester, find.text('No documented evidence for this goal yet.'));
    expect(find.text('No documented evidence for this goal yet.'), findsOneWidget);
    expect(next.paths, hasLength(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets('version goal opens its exact evidence history', (tester) async {
    final plan = IepPlan.fromJson(newSavedPlan()), source = evidenceSource(), f = EvidenceFixture(evidenceSource());
    final version = plan.versions.single;
    await tester.pumpWidget(curriculumHost(IepVersionScreen(plan: plan, version: version,
        evaluationGateway: EvaluationHistoryHttpFixture().repository, evidenceGateway: f.repository), 'en'));
    await tester.pumpAndSettle();
    final button = find.byKey(ValueKey('iep-goal-evidence-${source.goal.id}'));
    await revealEvidence(tester, button);
    await tester.tap(button); await tester.pumpAndSettle();
    expect(find.byType(IepGoalEvidenceScreen), findsOneWidget);
    expect(f.paths.single, contains('/goals/${source.goal.id}/evidence'));
    expect(tester.takeException(), isNull);
  });
}

