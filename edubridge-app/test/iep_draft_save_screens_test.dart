import 'dart:async';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/iep/iep_draft_save_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart' show curriculumHost, resumeCurriculum;
import 'iep_draft_save_fixture.dart';
import 'iep_draft_screens_test.dart' show tapDraft, revealDraft;

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      void viewport(WidgetTester tester) {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }
      testWidgets('confirmed server draft is distinct from approval $language $width', (tester) async {
        viewport(tester);
        final f = IepDraftSaveFixture();
        await tester.pumpWidget(curriculumHost(IepDraftSaveScreen(draft: saveDraft(), gateway: f.repository), language));
        await tester.pumpAndSettle();
        await tapDraft(tester, 'iep-save-to-server');
        expect(f.posts, isEmpty);
        await tapDraft(tester, 'iep-confirm-save');
        final l = await AppLocalizations.delegate.load(Locale(language));
        expect(find.text(l.iepSaveSuccess), findsOneWidget);
        expect(find.text(l.iepDraft), findsOneWidget);
        expect(find.text(l.iepApproved), findsNothing);
        expect(f.posts, hasLength(1));
        await resumeCurriculum(tester);
        expect(f.posts, hasLength(1));
        expect(tester.takeException(), isNull);
      });
      testWidgets('unavailable draft service never saves $language $width', (tester) async {
        viewport(tester);
        final f = IepDraftSaveFixture()..optionsStatus = 404;
        await tester.pumpWidget(curriculumHost(IepDraftSaveScreen(draft: saveDraft(), gateway: f.repository), language));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('iep-save-error')), findsOneWidget);
        expect(tester.widget<FilledButton>(find.byKey(const ValueKey('iep-save-to-server'))).onPressed, isNull);
        expect(find.byKey(const ValueKey('iep-server-saved')), findsNothing);
        expect(f.posts, isEmpty);
        expect(tester.takeException(), isNull);
      });
      testWidgets('resume invalidates draft save confirmation $language $width', (tester) async {
        viewport(tester);
        final f = IepDraftSaveFixture();
        await tester.pumpWidget(curriculumHost(IepDraftSaveScreen(draft: saveDraft(), gateway: f.repository), language));
        await tester.pumpAndSettle();
        await tapDraft(tester, 'iep-save-to-server');
        await resumeCurriculum(tester);
        await tapDraft(tester, 'iep-confirm-save');
        expect(f.posts, isEmpty);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('pending save blocks back; uncertain completion cannot be replayed', (tester) async {
    final f = IepDraftSaveFixture()..pendingPost = Completer<void>()..failConfirmation = true;
    await tester.pumpWidget(curriculumHost(Builder(builder: (context) => Scaffold(body: TextButton(
      child: const Text('Open save'), onPressed: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => IepDraftSaveScreen(draft: saveDraft(), gateway: f.repository))),
    ))), 'en'));
    await tester.tap(find.text('Open save'));
    await tester.pumpAndSettle();
    await tapDraft(tester, 'iep-save-to-server');
    final confirm = find.byKey(const ValueKey('iep-confirm-save'));
    await revealDraft(tester, confirm);
    await tester.tap(confirm);
    await tester.pump();
    await tester.pump();
    await tester.pageBack();
    await tester.pump();
    expect(find.byType(IepDraftSaveScreen), findsOneWidget);
    f.pendingPost!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('iep-save-uncertain')), findsOneWidget);
    expect(find.byKey(const ValueKey('iep-server-saved')), findsNothing);
    await tapDraft(tester, 'iep-reload-save-options');
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('iep-save-to-server'))).onPressed, isNull);
    expect(f.posts, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
