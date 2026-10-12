import 'package:edubridge_app/screens/chat/aac_quick_bar.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('child profile limits cards and preserves access to later cards', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AacQuickBar(
      profile: const AccessibilityProfile(type: DisabilityType.none, maxOptionsCount3: true),
      onItemSelected: (_, __) {},
    ))));
    expect(find.text('مرحباً'), findsOneWidget);
    expect(find.text('لا'), findsNothing);
    await tester.tap(find.text('صور أخرى'));
    await tester.pumpAndSettle();
    expect(find.text('لا'), findsOneWidget);
    expect(find.text('مرحباً'), findsNothing);
    await tester.tap(find.text('السابق'));
    await tester.pumpAndSettle();
    expect(find.text('مرحباً'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
