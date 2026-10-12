import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AccessibilityService.instance.resetSession());
  testWidgets('icon mode retains guidance for buttons without icons', (tester) async {
    AccessibilityService.instance.profile.value = const AccessibilityProfile(
      type: DisabilityType.none, iconOnlyMode: true,
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Column(children: [
      AdaptiveButton(label: 'استمع', icon: Icons.volume_up, onPressed: () {}),
      AdaptiveButton(label: 'التالي', onPressed: () {}),
    ]))));
    expect(find.text('استمع'), findsNothing);
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    expect(find.byTooltip('استمع'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
