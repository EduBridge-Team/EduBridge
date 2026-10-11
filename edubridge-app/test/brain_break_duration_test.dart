import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/widgets/accessibility/brain_break_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('duration survives profile copy and serialization with safe bounds', () {
    const profile = AccessibilityProfile(type: DisabilityType.none, brainBreakDurationSeconds: 60);
    expect(AccessibilityProfile.fromJson(profile.copyWith(slowSpeech: true).toJson()).brainBreakDurationSeconds, 60);
    expect(AccessibilityProfile.fromJson({'brainBreakDurationSeconds': -10}).brainBreakDurationSeconds, 15);
    expect(AccessibilityProfile.fromJson({'brainBreakDurationSeconds': 999}).brainBreakDurationSeconds, 120);
    expect(AccessibilityProfile.fromJson({}).brainBreakDurationSeconds, 30);
  });

  testWidgets('specialist duration controls automatic return', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) =>
      TextButton(onPressed: () => BrainBreakDialog.show(context, profile: const AccessibilityProfile(
        type: DisabilityType.none, brainBreakDurationSeconds: 60,
      )), child: const Text('open'))))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    expect(find.byType(BrainBreakDialog), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.byType(BrainBreakDialog), findsNothing);
  });
}
