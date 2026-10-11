import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/services/simple_language_service.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_button.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_text.dart';
import 'package:edubridge_app/widgets/accessibility/brain_break_overlay.dart';
import 'package:flutter/material.dart';
import 'package:edubridge_app/widgets/accessibility/step_by_step_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AccessibilityService.instance.resetSession());

  test('reading lines preserve every word including late instructions', () {
    const text = 'اقرأ السؤال ثم اختر الصورة المناسبة وبعد ذلك اضغط على الزر لإرسال الإجابة';
    final result = SimpleLanguageService.instance.readingLines(text, wordsPerLine: 4);
    expect(result.replaceAll('\n', ' '), text);
    expect(result.replaceAll('\n', ' '), endsWith('لإرسال الإجابة'));
    expect(SimpleLanguageService.instance.readingLines(''), '');
    expect(SimpleLanguageService.instance.readingLines('واحد اثنان', wordsPerLine: 0), 'واحد\nاثنان');
  });

  test('reading lines separate complete sentences without dropping punctuation', () {
    const text = 'اقرأ السؤال. اختر الصورة؟ ثم اضغط تأكيد!';
    expect(SimpleLanguageService.instance.readingLines(text),
      'اقرأ السؤال.\nاختر الصورة؟\nثم اضغط تأكيد!');
  });

  testWidgets('empty step lesson stays readable after initial reading delay', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StepByStepLesson(
      lessonTitle: 'درس', steps: [], childName: 'طفل',
    )));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('لا توجد خطوات لهذا الدرس بعد.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
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

  testWidgets('untimed rest waits for explicit readiness', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(
        onPressed: () => BrainBreakDialog.show(context,
          profile: const AccessibilityProfile(type: DisabilityType.none, sensoryCalmMode: true, noTimers: true)),
        child: const Text('راحة'),
      ),
    ))));
    await tester.tap(find.text('راحة'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('وقت الراحة'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('استرح بالطريقة المريحة لك'), findsOneWidget);
    await tester.tap(find.text('اقتراح آخر'));
    await tester.pump();
    expect(find.text('يمكنك طلب مساعدة شخص معك'), findsOneWidget);
    await tester.tap(find.text('جاهز'));
    await tester.pumpAndSettle();
    expect(find.text('وقت الراحة'), findsNothing);
  });
  testWidgets('timed break permits two extensions and resumes at ninety seconds', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(
        onPressed: () => BrainBreakDialog.show(context,
          profile: const AccessibilityProfile(type: DisabilityType.none, sensoryCalmMode: true)),
        child: const Text('راحة'),
      ),
    ))));
    await tester.tap(find.text('راحة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أحتاج وقتاً أكثر (+30 ثانية)'));
    await tester.pump();
    await tester.tap(find.text('أحتاج وقتاً أكثر (+30 ثانية)'));
    await tester.pump();
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton,
      'اكتملت التمديدات')).onPressed, isNull);
    await tester.pump(const Duration(seconds: 85));
    expect(find.text('سنكمل بعد 5 ثوانٍ'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('وقت الراحة'), findsNothing);
    expect(find.text('راحة'), findsOneWidget);
  });

}
