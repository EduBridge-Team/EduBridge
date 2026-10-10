import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/simple_language_service.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_button.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_text.dart';
import 'package:edubridge_app/widgets/accessibility/brain_break_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AccessibilityService.instance.resetSession());

  test('reading lines preserve every word including late instructions', () {
    const text = 'اقرأ السؤال ثم اختر الصورة المناسبة وبعد ذلك اضغط على الزر لإرسال الإجابة';
    final result = SimpleLanguageService.instance.readingLines(text, wordsPerLine: 4);
    expect(result.replaceAll('\n', ' '), text);
    expect(result, contains('لإرسال الإجابة'));
    expect(SimpleLanguageService.instance.readingLines(''), '');
    expect(SimpleLanguageService.instance.readingLines('واحد اثنان', wordsPerLine: 0), 'واحد\nاثنان');
  });

  test('simplification retains educational and clinical meaning', () {
    const text = 'التقييم ليس تشخيص اضطراب أو علاج القلق والاكتئاب';
    expect(SimpleLanguageService.instance.simplify(text), text);
  });

  testWidgets('short sentence adaptation retains the complete instruction', (tester) async {
    AccessibilityService.instance.profile.value = const AccessibilityProfile(
      type: DisabilityType.none, shortSentences: true,
    );
    const text = 'اختر الصورة التي تحتوي على ثلاثة أقلام ثم اضغط على تأكيد الإجابة';
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AdaptiveText(text))));
    final rendered = tester.widget<Text>(find.byType(Text));
    expect(rendered.data!.replaceAll('\n', ' '), text);
    expect(rendered.overflow, TextOverflow.visible);
  });

  testWidgets('long adaptive button wraps with large system text', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: Center(child: SizedBox(width: 240, child: AdaptiveButton(
        label: 'اضغط هنا للاستماع إلى التعليمات كاملة',
        icon: Icons.volume_up, onPressed: () {},
      ))),
    ))));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ElevatedButton)).height, greaterThanOrEqualTo(56));
  });

  testWidgets('suggested rest duration never forces a child back to learning', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(
        onPressed: () => BrainBreakDialog.show(context,
          profile: const AccessibilityProfile(type: DisabilityType.none, sensoryCalmMode: true)),
        child: const Text('راحة'),
      ),
    ))));
    await tester.tap(find.text('راحة'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('وقت الراحة'), findsOneWidget);
    expect(find.text('يمكنك الاستمرار في الراحة'), findsOneWidget);
    expect(find.text('استرح بالطريقة المريحة لك'), findsOneWidget);
    await tester.tap(find.text('اقتراح آخر'));
    await tester.pump();
    expect(find.text('يمكنك طلب مساعدة شخص معك'), findsOneWidget);
    await tester.tap(find.text('جاهز'));
    await tester.pumpAndSettle();
    expect(find.text('وقت الراحة'), findsNothing);
  });
}
