import 'dart:async';

import 'package:edubridge_app/model/schools/director_evidence.dart';
import 'package:edubridge_app/screens/school_directors/evidence/director_evidence_screen.dart';
import 'package:edubridge_app/screens/school_directors/evidence/director_verification_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'director_evidence_fakes.dart';
import 'director_evidence_screen_test.dart' show host, screen, selectIdentity;
import 'school_directors_fakes.dart';

Future<void> revealEvidenceAction(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> confirmEvidence(WidgetTester tester) async {
  final confirm = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(FilledButton),
  );
  await tester.ensureVisible(confirm);
  await tester.tap(confirm);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      void viewport(WidgetTester tester) {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }

      testWidgets(
        'evidence scope replacement clears identity selection $language $width',
        (tester) async {
          viewport(tester);
          final first = FakeDirectorEvidence(), second = FakeDirectorEvidence();
          await tester.pumpWidget(host(screen(first), language, scale: 2));
          await tester.pumpAndSettle();
          await selectIdentity(tester);
          await tester.pumpWidget(host(screen(second), language, scale: 2));
          await tester.pumpAndSettle();
          final submit = find.byKey(
            const ValueKey('director-verification-submit'),
          );
          expect(tester.widget<FilledButton>(submit).onPressed, isNull);
          expect(find.byType(DirectorVerificationCard), findsOneWidget);
          expect(first.writes, 0);
          expect(second.writes, 0);
          expect(tester.takeException(), isNull);
        },
      );

      for (final remove in [false, true]) {
        testWidgets(
          'refresh invalidates evidence ${remove ? 'removal' : 'review'} confirmation $language $width',
          (tester) async {
            viewport(tester);
            final gateway = FakeDirectorEvidence();
            await tester.pumpWidget(host(screen(gateway), language, scale: 2));
            await tester.pumpAndSettle();
            final controller = tester
                .widget<DirectorVerificationCard>(
                  find.byType(DirectorVerificationCard),
                )
                .controller;
            if (!remove) await selectIdentity(tester);
            final action = find.byKey(
              ValueKey(
                remove
                    ? 'director-document-remove-70'
                    : 'director-verification-submit',
              ),
            );
            await revealEvidenceAction(tester, action);
            await tester.tap(action);
            await tester.pumpAndSettle();
            gateway.state = evidenceState();
            expect(find.byType(AlertDialog), findsOneWidget);
            await controller.reload();
            await tester.pumpAndSettle();
            await confirmEvidence(tester);
            expect(gateway.writes, 0);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'replacing school while picker is pending cannot upload old draft',
    (tester) async {
      final gateway = FakeDirectorEvidence();
      final picked = Completer<DirectorDocumentDraft?>();
      await tester.pumpWidget(
        host(screen(gateway, picker: (_) => picked.future), 'en'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('director-document-upload')));
      await tester.pump();
      await tester.pumpWidget(
        host(
          DirectorEvidenceScreen(
            school: directorSchoolB,
            director: directorProfile,
            gateway: gateway,
          ),
          'en',
        ),
      );
      await tester.pumpAndSettle();
      picked.complete(evidenceDraft());
      await tester.pumpAndSettle();
      expect(gateway.writes, 0);
      expect(
        find.byKey(const ValueKey('director-evidence-saved')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
