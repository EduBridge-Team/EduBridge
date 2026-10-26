import 'dart:async';
import 'dart:convert';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/evaluation_history/evaluation_record_screen.dart';
import 'package:edubridge_app/screens/iep/iep_draft_editor_screen.dart';
import 'package:edubridge_app/screens/iep/iep_draft_goal_card.dart';
import 'package:edubridge_app/screens/iep/iep_draft_preview_screen.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'curriculum_ui_support.dart' show curriculumHost;
import 'evaluation_history_fixture.dart';
import 'iep_draft_screens_test.dart'
    show
        addDraftGoal,
        chooseDraftEvaluation,
        fillPlan,
        inputDraft,
        revealDraft,
        tapDraft;

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets(
        'review complete unsaved snapshot and return at $width in $language',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final fixture = EvaluationHistoryHttpFixture();
          final strings = await AppLocalizations.delegate.load(
            Locale(language),
          );
          await tester.pumpWidget(
            curriculumHost(
              IepDraftEditorScreen(
                childId: 8,
                childName: 'محمود',
                evaluationGateway: fixture.repository,
              ),
              language,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('iep-preview-draft')), findsNothing);
          expect(
            find.byKey(const ValueKey('iep-evaluation-reference')),
            findsNothing,
          );
          await fillPlan(tester);
          await inputDraft(tester, 'summary', 'ملخص أصلي\nلا يترجم');
          await inputDraft(
            tester,
            'accommodations',
            ' وقت إضافي \n\nتعليم بصري',
          );
          await addDraftGoal(tester);
          await tapDraft(tester, 'iep-verify-draft');
          await tapDraft(tester, 'iep-preview-draft');
          expect(find.byType(IepDraftPreviewScreen), findsOneWidget);
          expect(find.byType(BrandAppBar), findsOneWidget);
          expect(find.text(strings.iepComposePreviewNotice), findsOneWidget);
          expect(find.text('خطة محمود الأصلية'), findsOneWidget);
          expect(find.text('ملخص أصلي\nلا يترجم'), findsOneWidget);
          expect(find.text('وقت إضافي'), findsOneWidget);
          expect(find.text('تعليم بصري'), findsOneWidget);
          final preview = tester.widget<IepDraftPreviewScreen>(
            find.byType(IepDraftPreviewScreen),
          );
          expect(preview.draft.childId, 8);
          expect(preview.draft.evaluationId, 11);
          expect(preview.draft.start, DateTime(2026, 9, 1));
          expect(preview.draft.end, DateTime(2027, 6, 1));
          expect(preview.draft.reviewOn, DateTime(2027, 1, 1));
          final card = tester.widget<IepDraftGoalCard>(
            find.byType(IepDraftGoalCard),
          );
          expect(card.goal.baseline, 8);
          expect(card.goal.target, 2.5);
          expect(card.goal.unit, 'مرات في الجلسة');
          expect(card.goal.method, 'ملاحظة مباشرة في كل جلسة');
          expect(card.goal.responsible, 'المختص');
          expect(card.onEdit, isNull);
          expect(card.onRemove, isNull);
          expect(find.text(strings.edit), findsNothing);
          expect(find.text(strings.delete), findsNothing);
          await tapDraft(tester, 'iep-evaluation-reference');
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
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          expect(find.byType(IepDraftPreviewScreen), findsOneWidget);
          await tapDraft(tester, 'iep-return-to-editor');
          expect(find.byType(IepDraftPreviewScreen), findsNothing);
          expect(find.byType(AlertDialog), findsNothing);
          expect(find.byType(IepDraftGoalCard), findsOneWidget);
          await inputDraft(tester, 'title', 'عنوان معدل');
          expect(find.byKey(const ValueKey('iep-preview-draft')), findsNothing);
          expect(preview.draft.title, 'خطة محمود الأصلية');
          await tapDraft(tester, 'iep-verify-draft');
          await tapDraft(tester, 'iep-preview-draft');
          expect(find.text('عنوان معدل'), findsOneWidget);
          expect(fixture.paths, [
            '/evaluations/child/8',
            '/evaluations/child/8',
            '/evaluations/child/8',
          ]);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('changing a reference ignores its old in-flight response', (
    tester,
  ) async {
    final fixture = EvaluationHistoryHttpFixture();
    await tester.pumpWidget(
      curriculumHost(
        IepDraftEditorScreen(childId: 8, evaluationGateway: fixture.repository),
        'en',
      ),
    );
    await tester.pumpAndSettle();
    await chooseDraftEvaluation(tester);
    final pending = Completer<http.Response>();
    fixture.pending = pending;
    final open = find.byKey(const ValueKey('iep-evaluation-reference'));
    await revealDraft(tester, open);
    await tester.tap(open);
    await tester.pump();
    expect(fixture.reads, 2);
    // Loading has a progress animation, so avoid pumpAndSettle until replaced.
    final choice = find.descendant(
      of: find.byKey(const ValueKey('iep-choose-evaluation')),
      matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
    );
    await Scrollable.ensureVisible(tester.element(choice));
    await tester.tap(choice);
    await tester.pump(const Duration(milliseconds: 400));
    final option = find.descendant(
      of: find.byType(SimpleDialog),
      matching: find.textContaining('#10'),
    );
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pumpAndSettle();
    fixture.pending = null;
    pending.complete(
      http.Response(
        jsonEncode({
          'evaluations': [evaluationJson()],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EvaluationRecordScreen), findsNothing);
    await tapDraft(tester, 'iep-evaluation-reference');
    expect(
      tester
          .widget<EvaluationRecordScreen>(find.byType(EvaluationRecordScreen))
          .record
          .id,
      10,
    );
    expect(fixture.reads, 3);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'a missing reference cannot open a record or discard entered values',
    (tester) async {
      final fixture = EvaluationHistoryHttpFixture();
      final strings = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(
        curriculumHost(
          IepDraftEditorScreen(
            childId: 8,
            evaluationGateway: fixture.repository,
          ),
          'en',
        ),
      );
      await tester.pumpAndSettle();
      await fillPlan(tester);
      await addDraftGoal(tester);
      await tapDraft(tester, 'iep-verify-draft');
      await tapDraft(tester, 'iep-preview-draft');
      fixture.records = [];
      await tapDraft(tester, 'iep-evaluation-reference');
      expect(find.byType(EvaluationRecordScreen), findsNothing);
      expect(
        find.text(strings.evaluationHistoryInvalidResponse),
        findsOneWidget,
      );
      await tapDraft(tester, 'iep-return-to-editor');
      expect(find.byType(IepDraftGoalCard), findsOneWidget);
      expect(find.text(strings.iepComposeNoEvaluations), findsOneWidget);
      expect(find.byKey(const ValueKey('iep-preview-draft')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
