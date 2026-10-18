import 'package:edubridge_app/widgets/disability/disability_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester, ValueChanged<String?> done, {String? current}) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(onPressed: () async {
        done(await showModalBottomSheet<String>(context: context,
          isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => DisabilityPickerSheet(figmaS30: true, currentValue: current)));
      }, child: const Text('فتح')),
    ))));
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('S30 searches real cases and returns the selected value', (tester) async {
    String? result;
    await open(tester, (value) => result = value);
    expect(find.text('اختر نوع الإعاقة'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('s30-search')), 'عمى الألوان');
    await tester.pumpAndSettle();
    expect(find.text('عمى الألوان'), findsWidgets);
    await tester.tap(find.widgetWithText(ListTile, 'عمى الألوان'));
    await tester.pumpAndSettle();
    expect(result, 'عمى الألوان');
    expect(tester.takeException(), isNull);
  });

  testWidgets('S30 empty search can clear and Other remains selectable', (tester) async {
    String? result;
    await open(tester, (value) => result = value);
    await tester.enterText(find.byKey(const ValueKey('s30-search')), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج'), findsOneWidget);
    await tester.tap(find.byTooltip('مسح البحث'));
    await tester.pumpAndSettle();
    expect(find.text('الإعاقات البصرية'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('s30-search')), 'أخرى');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('s30-other')));
    await tester.pumpAndSettle();
    expect(result, 'أخرى');
    expect(tester.takeException(), isNull);
  });

  testWidgets('S30 opens the current category and close does not change selection', (tester) async {
    var closed = false;
    String? result;
    await open(tester, (value) { closed = true; result = value; }, current: 'عمى الألوان');
    final tile = tester.widget<ListTile>(find.widgetWithText(ListTile, 'عمى الألوان'));
    expect(tile.selected, isTrue);
    await tester.tap(find.byTooltip('إغلاق'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}
