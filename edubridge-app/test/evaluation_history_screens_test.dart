import 'dart:async';
import 'dart:convert';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/evaluation_history/evaluation_history_card.dart';
import 'package:edubridge_app/screens/evaluation_history/evaluation_history_screen.dart';
import 'package:edubridge_app/screens/evaluation_history/evaluation_record_screen.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'curriculum_ui_support.dart'
    show curriculumHost, revealCurriculum, resumeCurriculum;
import 'evaluation_history_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets(
        'history/details/refresh are readable in $language at $width',
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
              EvaluationHistoryScreen(
                childId: 8,
                childName: 'محمود',
                gateway: fixture.repository,
              ),
              language,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(BrandAppBar), findsOneWidget);
          expect(
            tester
                .widgetList<EvaluationHistoryCard>(
                  find.byType(EvaluationHistoryCard),
                )
                .first
                .record
                .id,
            11,
          );
          final card = find.byKey(const ValueKey('evaluation-record-11'));
          await revealCurriculum(tester, card);
          await tester.tap(card);
          await tester.pumpAndSettle();
          expect(find.byType(EvaluationRecordScreen), findsOneWidget);
          expect(find.byType(BrandAppBar), findsOneWidget);
          expect(find.byType(BackButton), findsOneWidget);
          final plan = find.byKey(const ValueKey('evaluation-detail-plan'));
          final scroll = find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first;
          if (plan.evaluate().isEmpty)
            await tester.scrollUntilVisible(plan, 250, scrollable: scroll);
          await tester.ensureVisible(plan);
          await tester.pumpAndSettle();
          expect(tester.widget<SelectableText>(plan).data, originalHistoryPlan);
          final methods = find.byKey(
            const ValueKey('evaluation-detail-method-1'),
          );
          if (methods.evaluate().isEmpty)
            await tester.scrollUntilVisible(methods, 200, scrollable: scroll);
          await tester.ensureVisible(methods);
          await tester.pumpAndSettle();
          expect(find.text('طريقة المختص الأصلية'), findsOneWidget);
          expect(
            fixture.reads,
            1,
          ); // Opening a snapshot is read-only and needs no write.
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          fixture.records = [];
          final historyScroll = find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first;
          tester.state<ScrollableState>(historyScroll).position.jumpTo(0);
          await tester.pump();
          await tester.drag(find.byType(ListView), const Offset(0, 350));
          await tester.pumpAndSettle();
          expect(fixture.reads, 2);
          expect(find.text(strings.noRecordedEvaluation), findsOneWidget);
          fixture.status = 403;
          await resumeCurriculum(tester);
          expect(
            find.byKey(const ValueKey('evaluation-history-empty')),
            findsNothing,
          );
          expect(find.text(strings.evaluationHistoryForbidden), findsOneWidget);
          fixture.status = 200;
          fixture.records = [evaluationJson()];
          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pumpAndSettle();
          expect(find.byType(EvaluationHistoryCard), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
  testWidgets(
    'late response from a previous child never replaces the new history',
    (tester) async {
      final old = EvaluationHistoryHttpFixture()
        ..pending = Completer<http.Response>();
      final current = EvaluationHistoryHttpFixture();
      await tester.pumpWidget(
        curriculumHost(
          EvaluationHistoryScreen(childId: 9, gateway: old.repository),
          'en',
        ),
      );
      await tester.pump();
      await tester.pumpWidget(
        curriculumHost(
          EvaluationHistoryScreen(childId: 8, gateway: current.repository),
          'en',
        ),
      );
      await tester.pumpAndSettle();
      old.pending!.complete(
        http.Response(
          jsonEncode({
            'evaluations': [evaluationJson()],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EvaluationHistoryCard), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('evaluation-history-error')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
