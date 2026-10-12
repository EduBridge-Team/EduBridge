import 'package:edubridge_app/widgets/accessibility/voice_draft_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('disabled dictation keeps the draft unchanged', (tester) async {
    final controller = TextEditingController(text: 'إجابتي');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      VoiceDraftButton(controller: controller, enabled: false))));
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
    expect(controller.text, 'إجابتي');
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
