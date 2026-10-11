import 'package:edubridge_app/screens/child_accessibility/child_accessibility_settings_screen.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('feature sections provide a local Material surface for tiles', (tester) async {
    var enabled = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => buildFeatureSection(
        title: 'التكيف', icon: Icons.accessibility, color: Colors.teal,
        c: JisrColors.of(context),
        children: [sw('الحركة', 'تقليل الحركة', false, (value) => enabled = value)],
      ),
    ))));
    final context = tester.element(find.byType(SwitchListTile));
    final surface = context.findAncestorWidgetOfExactType<Material>();
    expect(surface, isNotNull);
    expect(surface!.shape, isA<RoundedRectangleBorder>());
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(enabled, isTrue);
    expect(tester.takeException(), isNull);
  });
}
