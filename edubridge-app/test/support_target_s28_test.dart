import 'package:edubridge_app/screens/specialist/support_target_dialog_s28.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final target in SupportRecommendationTarget.values) {
    testWidgets('S28 returns ${target.name} only after selection and Next', (tester) async {
      SupportRecommendationTarget? result;
      var closed = false;
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
        builder: (context) => TextButton(onPressed: () async {
          result = await showDialog<SupportRecommendationTarget>(context: context,
            builder: (_) => const SupportTargetDialogS28(childName: 'محمود'));
          closed = true;
        }, child: const Text('فتح')),
      ))));
      await tester.tap(find.text('فتح'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.getCenter(find.text('إلغاء')).dx,
        greaterThan(tester.getCenter(find.text('التالي')).dx));
      await tester.tap(find.byKey(const ValueKey('s28-next')));
      await tester.pumpAndSettle();
      expect(find.text('اختر جهة اقتراح الدعم'), findsOneWidget);
      expect(closed, isFalse);
      await tester.tap(find.byKey(ValueKey('s28-${target.name}')));
      await tester.pumpAndSettle();
      expect(closed, isFalse);
      expect(find.text('اختر جهة اقتراح الدعم'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('s28-next')));
      await tester.pumpAndSettle();
      expect(result, target);
      expect(closed, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('S28 cancel returns no target even after a selection', (tester) async {
    var closed = false;
    SupportRecommendationTarget? result;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(onPressed: () async {
        result = await showDialog<SupportRecommendationTarget>(context: context,
          builder: (_) => const SupportTargetDialogS28(childName: 'اسم طفل طويل للاختبار'));
        closed = true;
      }, child: const Text('فتح')),
    ))));
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('s28-parent')));
    await tester.tap(find.byKey(const ValueKey('s28-cancel')));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}
