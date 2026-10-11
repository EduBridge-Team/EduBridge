import 'package:edubridge_app/screens/chat/aac_quick_bar.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AccessibilityService.instance.resetSession());

  testWidgets('disabled communication cards do not change the message', (tester) async {
    var selections = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AacQuickBar(
      enabled: false,
      onItemSelected: (_, __) => selections++,
    ))));
    await tester.tap(find.text('مرحباً'));
    await tester.longPress(find.text('مرحباً'));
    expect(selections, 0);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('communication cards fit large text and touch targets', (tester) async {
    AccessibilityService.instance.applicationProfile.value = const AccessibilityProfile(
      type: DisabilityType.none, extraLargeTouchTargets: true,
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: AacQuickBar(enabled: false, onItemSelected: (_, __) {}),
    ))));
    expect(tester.takeException(), isNull);
    final label = tester.widget<Text>(find.text('مرحباً'));
    expect(label.overflow, isNot(TextOverflow.ellipsis));
    expect(label.maxLines, 3);
  });
}
