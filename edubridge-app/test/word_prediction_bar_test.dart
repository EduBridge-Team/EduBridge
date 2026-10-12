import 'package:edubridge_app/widgets/accessibility/word_prediction_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completion at caret preserves later words', () {
    const value = TextEditingValue(text: 'أنا أر ماء', selection: TextSelection.collapsed(offset: 6));
    final result = completeWord(value, 'أريد');
    expect(result.text, 'أنا أريد ماء');
    expect(result.selection.extentOffset, 8);
  });
  testWidgets('prediction respects enablement and completes without submitting', (tester) async {
    final controller = TextEditingController(text: 'أر');
    controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: WordPredictionBar(controller: controller, enabled: false))));
    expect(find.byType(ActionChip), findsNothing);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: WordPredictionBar(controller: controller, enabled: true))));
    await tester.tap(find.text('أريد'));
    await tester.pump();
    expect(controller.text, 'أريد');
    expect(find.byType(ActionChip), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
