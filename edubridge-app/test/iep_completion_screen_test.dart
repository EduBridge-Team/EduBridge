import 'package:edubridge_app/model/iep/iep_draft.dart';
import 'package:edubridge_app/model/iep/iep_edit_source.dart';
import 'package:edubridge_app/screens/iep/iep_completion_screen.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/iep/iep_completion_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart';
import 'iep_draft_save_fixture.dart';

class _Gateway implements IepCompletionGateway {
  bool enabled = true;
  bool unavailable = false;
  bool uncertain = false;
  int completions = 0;
  final keys = <String>[];
  @override
  Future<IepCompletionOptions> options() async {
    if (unavailable) {
      throw const EnrollmentApiException(EnrollmentFailure.unavailable);
    }
    return IepCompletionOptions(8, 'r1', enabled, {11});
  }
  @override
  Future<void> complete(IepPlanDraft draft, IepCompletionOptions expected, String key) async {
    completions++;
    keys.add(key);
    if (uncertain) throw const EnrollmentApiException(EnrollmentFailure.uncertain);
  }
  @override
  Future<void> completeExisting(IepEditSource source, IepPlanDraft draft,
      IepCompletionOptions expected, String key) async {
    throw StateError('No saved draft supplied to this test');
  }
}

void main() {
  for (final language in ['ar', 'en']) {
    testWidgets('Done confirms once before saying teacher can see plan $language',
        (tester) async {
      final gateway = _Gateway();
      await tester.pumpWidget(curriculumHost(
        IepCompletionScreen(draft: saveDraft(), childName: 'محمود', gateway: gateway),
        language,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('iep-complete-confirmed')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('iep-complete-submit')));
      await tester.pumpAndSettle();
      expect(gateway.completions, 0);
      await tester.tap(find.byKey(const ValueKey('iep-complete-confirm')));
      await tester.pumpAndSettle();
      expect(gateway.completions, 1);
      expect(gateway.keys.single, matches(RegExp(r'^[a-f0-9]{32}$')));
      expect(find.byKey(const ValueKey('iep-complete-confirmed')), findsOneWidget);
      expect(find.byKey(const ValueKey('iep-complete-submit')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('missing completion backend is not a successful action', (tester) async {
    final gateway = _Gateway()..unavailable = true;
    await tester.pumpWidget(curriculumHost(
      IepCompletionScreen(draft: saveDraft(), gateway: gateway), 'ar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('iep-complete-error')), findsOneWidget);
    expect(tester.widget<FilledButton>(
        find.byKey(const ValueKey('iep-complete-submit'))).onPressed, isNull);
    expect(gateway.completions, 0);
  });

  testWidgets('uncertain completion cannot be resubmitted', (tester) async {
    final gateway = _Gateway()..uncertain = true;
    await tester.pumpWidget(curriculumHost(
      IepCompletionScreen(draft: saveDraft(), gateway: gateway), 'en'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('iep-complete-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('iep-complete-confirm')));
    await tester.pumpAndSettle();
    expect(gateway.completions, 1);
    expect(find.byKey(const ValueKey('iep-complete-confirmed')), findsNothing);
    expect(find.byKey(const ValueKey('iep-complete-error')), findsOneWidget);
    expect(tester.widget<FilledButton>(
        find.byKey(const ValueKey('iep-complete-submit'))).onPressed, isNull);
  });
}
