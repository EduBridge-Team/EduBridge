import 'package:edubridge_app/widgets/accessibility/word_prediction_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('composition and selection preserve the child draft', (tester) async {
    final controller = TextEditingController.fromValue(const TextEditingValue(
      text: 'أر', selection: TextSelection.collapsed(offset: 2),
      composing: TextRange(start: 0, end: 2)));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      WordPredictionBar(controller: controller, enabled: true))));
    expect(find.byType(ActionChip), findsNothing);
    controller.value = const TextEditingValue(text: 'أر',
      selection: TextSelection(baseOffset: 0, extentOffset: 2));
    await tester.pump();
    expect(find.byType(ActionChip), findsNothing);
    expect(controller.text, 'أر');
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('suggestions are unique, reachable and limited to three', (tester) async {
    final controller = TextEditingController(text: 'م');
    controller.selection = const TextSelection.collapsed(offset: 1);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: WordPredictionBar(controller: controller, enabled: true,
        words: const ['مساعدة', 'مساعدة', 'ماء', 'مرحبا', 'ممتاز'])))));
    expect(find.byType(ActionChip), findsNWidgets(3));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('مساعدة'));
    await tester.pump();
    expect(controller.text, 'مساعدة');
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

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
