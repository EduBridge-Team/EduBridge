import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/iep/iep_draft_editor_screen.dart';
import 'package:edubridge_app/screens/iep/iep_draft_goal_card.dart';
import 'package:edubridge_app/screens/iep/iep_goal_editor_screen.dart';
import 'package:edubridge_app/screens/iep/iep_history_screen.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart' show curriculumHost, resumeCurriculum;
import 'evaluation_history_fixture.dart';
import 'iep_http_fixture.dart';

Future<void> revealDraft(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> tapDraft(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await revealDraft(tester, finder);
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> inputDraft(WidgetTester tester, String name, String text) async {
  final finder = find.byKey(ValueKey('iep-input-$name'));
  await revealDraft(tester, finder);
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

Future<void> chooseDraftEvaluation(WidgetTester tester) async {
  final finder = find.descendant(
    of: find.byKey(const ValueKey('iep-choose-evaluation')),
    matching: find.byWidgetPredicate((w) => w is OutlinedButton),
  );
  await revealDraft(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  final option = find.descendant(
    of: find.byType(SimpleDialog),
    matching: find.textContaining('#11'),
  );
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> fillPlan(WidgetTester tester) async {
  await chooseDraftEvaluation(tester);
  await inputDraft(tester, 'title', 'خطة محمود الأصلية');
  await inputDraft(tester, 'start', '٢٠٢٦-٠٩-٠١');
  await inputDraft(tester, 'end', '2027-06-01');
  await inputDraft(tester, 'review', '2027-01-01');
}

Future<void> addDraftGoal(WidgetTester tester) async {
  await tapDraft(tester, 'iep-add-goal');
  expect(find.byType(IepGoalEditorScreen), findsOneWidget);
  expect(find.byType(BrandAppBar), findsOneWidget);
  await inputDraft(tester, 'goal-title', 'تقليل المقاطعة في الجلسة');
  await inputDraft(tester, 'baseline', '٨');
  await inputDraft(tester, 'target', '٢٫٥');
  await inputDraft(tester, 'unit', 'مرات في الجلسة');
  await inputDraft(tester, 'method', 'ملاحظة مباشرة في كل جلسة');
  await inputDraft(tester, 'responsible', 'المختص');
  await tapDraft(tester, 'iep-accept-goal');
  expect(find.byType(IepGoalEditorScreen), findsNothing);
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('prepare only: goals, dates, discard at $width in $language', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final history = IepHttpFixture();
        final evaluations = EvaluationHistoryHttpFixture();
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await tester.pumpWidget(
          curriculumHost(
            IepHistoryScreen(
              childId: 8,
              childName: 'محمود',
              gateway: history.repository,
              evaluationGateway: evaluations.repository,
            ),
            language,
          ),
        );
        await tester.pumpAndSettle();
        await tapDraft(tester, 'iep-prepare-draft');
        expect(find.byType(IepDraftEditorScreen), findsOneWidget);
        expect(find.byType(BrandAppBar), findsOneWidget);
        expect(find.text(strings.iepComposeNotice), findsOneWidget);
        await fillPlan(tester);
        await inputDraft(tester, 'summary', 'مدخلات أصلية دون ترجمة');
        await inputDraft(tester, 'accommodations', 'وقت إضافي\n\nتعليم بصري');
        await addDraftGoal(tester);
        final goal = tester
            .widget<IepDraftGoalCard>(find.byType(IepDraftGoalCard))
            .goal;
        expect(goal.baseline, 8);
        expect(goal.target, 2.5);
        await tapDraft(tester, 'iep-verify-draft');
        expect(find.text(strings.iepComposeChecked), findsOneWidget);
        await inputDraft(tester, 'end', '2027-05-01');
        expect(find.byKey(const ValueKey('iep-draft-checked')), findsNothing);
        await tapDraft(tester, 'iep-verify-draft');
        expect(find.text(strings.iepComposeGoalsRequired), findsOneWidget);
        await inputDraft(tester, 'end', '2027-06-01');
        // Edit preserves the goal fields and returns to the same unsaved plan.
        final edit = find.descendant(
          of: find.byType(IepDraftGoalCard),
          matching: find.text(strings.edit),
        );
        await revealDraft(tester, edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        await inputDraft(tester, 'target', '٢');
        await tapDraft(tester, 'iep-accept-goal');
        expect(
          tester
              .widget<IepDraftGoalCard>(find.byType(IepDraftGoalCard))
              .goal
              .target,
          2,
        );
        await tapDraft(tester, 'iep-verify-draft');
        expect(find.text(strings.iepComposeChecked), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text(strings.iepComposeDiscardNotice), findsOneWidget);
        await tester.tap(find.text(strings.cancel));
        await tester.pumpAndSettle();
        expect(find.byType(IepDraftGoalCard), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('iep-discard-confirm')));
        await tester.pumpAndSettle();
        expect(find.byType(IepDraftEditorScreen), findsNothing);
        expect(evaluations.paths, ['/evaluations/child/8']);
        expect(history.reads, ['/children/8/iep-plans']);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'failed or expired reference reads preserve entries and prohibit validation',
    (tester) async {
      final evaluations = EvaluationHistoryHttpFixture()..status = 403;
      final gateway = evaluations.repository;
      final strings = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(
        curriculumHost(
          IepDraftEditorScreen(childId: 8, evaluationGateway: gateway),
          'en',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(strings.evaluationHistoryForbidden), findsOneWidget);
      await inputDraft(tester, 'title', 'مدخلات لا تضيع');
      final verify = find.byKey(const ValueKey('iep-verify-draft'));
      expect(tester.widget<FilledButton>(verify).onPressed, isNull);
      evaluations.status = 200;
      await tapDraft(tester, 'iep-reload-evaluations');
      await fillPlan(tester);
      await addDraftGoal(tester);
      await tapDraft(tester, 'iep-verify-draft');
      expect(find.text(strings.iepComposeChecked), findsOneWidget);
      evaluations.records = [];
      await resumeCurriculum(tester);
      expect(find.byKey(const ValueKey('iep-draft-checked')), findsNothing);
      expect(find.byType(IepDraftGoalCard), findsOneWidget);
      expect(tester.widget<FilledButton>(verify).onPressed, isNull);
      expect(find.text(strings.iepComposeNoEvaluations), findsOneWidget);
      expect(evaluations.reads, 3);
      // Reusing the widget for another child must clear the previous draft.
      await tester.pumpWidget(
        curriculumHost(
          IepDraftEditorScreen(childId: 9, evaluationGateway: gateway),
          'en',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(IepDraftGoalCard), findsNothing);
      final title = tester.widget<TextFormField>(
        find.byKey(const ValueKey('iep-input-title')),
      );
      expect(title.initialValue, '');
      expect(
        find.text(strings.evaluationHistoryInvalidResponse),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'removing a goal requires confirmation and invalidates the check',
    (tester) async {
      final evaluations = EvaluationHistoryHttpFixture();
      final strings = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(
        curriculumHost(
          IepDraftEditorScreen(
            childId: 8,
            evaluationGateway: evaluations.repository,
          ),
          'en',
        ),
      );
      await tester.pumpAndSettle();
      await fillPlan(tester);
      await addDraftGoal(tester);
      await tapDraft(tester, 'iep-verify-draft');
      final remove = find.descendant(
        of: find.byType(IepDraftGoalCard),
        matching: find.text(strings.delete),
      );
      await revealDraft(tester, remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.cancel));
      await tester.pumpAndSettle();
      expect(find.byType(IepDraftGoalCard), findsOneWidget);
      await revealDraft(tester, remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('iep-discard-confirm')));
      await tester.pumpAndSettle();
      expect(find.byType(IepDraftGoalCard), findsNothing);
      expect(find.byKey(const ValueKey('iep-draft-checked')), findsNothing);
      await tapDraft(tester, 'iep-verify-draft');
      expect(find.text(strings.iepComposeGoalsRequired), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'goal form rejects nonfinite measurements and out-of-plan dates',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final strings = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(
        curriculumHost(
          IepGoalEditorScreen(
            start: DateTime(2026, 9, 1),
            end: DateTime(2027, 6, 1),
          ),
          'en',
        ),
      );
      await tester.pumpAndSettle();
      await inputDraft(tester, 'goal-title', 'هدف');
      await inputDraft(tester, 'baseline', 'NaN');
      await inputDraft(tester, 'target', '2');
      await inputDraft(tester, 'unit', 'مرات');
      await inputDraft(tester, 'method', 'ملاحظة');
      await inputDraft(tester, 'goal-start', '2026-08-31');
      await tapDraft(tester, 'iep-accept-goal');
      expect(find.text(strings.iepComposeNumber), findsOneWidget);
      expect(find.text(strings.iepComposeGoalDates), findsOneWidget);
      expect(find.byType(IepGoalEditorScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
