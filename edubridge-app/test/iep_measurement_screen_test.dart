import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/screens/iep/iep_goal_evidence_screen.dart';
import 'package:edubridge_app/screens/iep/iep_measurement_summary.dart';
import 'curriculum_ui_support.dart';
import 'iep_goal_evidence_fixture.dart';

Future<void> revealMeasurement(WidgetTester tester, Finder target) async {
  final scroll = find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(target, 300, scrollable: scroll);
  await tester.ensureVisible(target); await tester.pumpAndSettle();
}
void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('measurement summary and numeric/qualitative filter $language $width at 2x', (tester) async {
        tester.view.physicalSize = Size(width, 2200); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final source = evidenceSource(), f = EvidenceFixture(evidenceSource());
        await tester.pumpWidget(curriculumHost(IepGoalEvidenceScreen(source: source, gateway: f.repository), language));
        await tester.pumpAndSettle();
        await revealMeasurement(tester, find.byKey(const ValueKey('iep-latest-measurement')));
        expect(tester.widget<Text>(find.byKey(const ValueKey('iep-latest-measurement'))).data, contains('0 ${source.goal.unit}'));
        final qualitative = find.byKey(const ValueKey('iep-evidence-filter-qualitative'));
        await revealMeasurement(tester, qualitative); await tester.tap(qualitative); await tester.pumpAndSettle();
        await revealMeasurement(tester, find.byKey(const ValueKey('iep-evidence-1')));
        expect(find.byKey(const ValueKey('iep-evidence-2')), findsNothing);
        final numeric = find.byKey(const ValueKey('iep-evidence-filter-numeric'));
        // Reset to top before searching upward in a lazy list.
        final scroll = find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first;
        tester.state<ScrollableState>(scroll).position.jumpTo(0); await tester.pumpAndSettle();
        await revealMeasurement(tester, numeric); await tester.tap(numeric); await tester.pumpAndSettle();
        await revealMeasurement(tester, find.byKey(const ValueKey('iep-evidence-2')));
        expect(find.byKey(const ValueKey('iep-evidence-1')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('resume rejects old in-flight summary after denied fresh read', (tester) async {
    final source = evidenceSource(), f = EvidenceFixture(evidenceSource()), pending = Completer<void>();
    f.pending = pending;
    await tester.pumpWidget(curriculumHost(IepGoalEvidenceScreen(source: source, gateway: f.repository), 'en'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    f.status = 403; tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(); pending.complete(); await tester.pumpAndSettle();
    expect(find.byType(IepMeasurementSummary), findsNothing);
    expect(find.byKey(const ValueKey('iep-evidence-2')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

