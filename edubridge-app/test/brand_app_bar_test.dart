import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('gradient keeps its physical direction and actions in $brightness', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(theme: ThemeData(brightness: brightness),
        home: Directionality(textDirection: TextDirection.rtl, child: Scaffold(
          appBar: BrandAppBar(title: const Text('الدروس'), toolbarHeight: 74,
            actions: [IconButton(tooltip: 'الإشعارات', onPressed: () { taps++; },
              icon: const Icon(Icons.notifications_outlined))]),
        ))));
      final bar = tester.widget<BrandAppBar>(find.byType(BrandAppBar));
      expect(bar.preferredSize.height, 74);
      expect(bar.foregroundColor, Colors.white);
      expect(bar.scrolledUnderElevation, 0);
      final background = bar.flexibleSpace! as DecoratedBox;
      final gradient = (background.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(gradient.begin, Alignment.centerLeft);
      expect(gradient.end, Alignment.centerRight);
      expect(gradient.colors, [const Color(0xFF1EB7C4), const Color(0xFF1969C1)]);
      await tester.tap(find.byTooltip('الإشعارات'));
      expect(taps, 1);
    });
  }

  testWidgets('shared toolbar retains navigation and rounded shape', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
        builder: (_) => const Scaffold(appBar: JisrAppBar(title: 'تفاصيل')))),
        child: const Text('افتح'))))));
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
    final bar = tester.widget<BrandAppBar>(find.byType(BrandAppBar));
    expect(bar.preferredSize.height, 72);
    expect(bar.shape, isA<RoundedRectangleBorder>());
    expect(bar.clipBehavior, Clip.antiAlias);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('افتح'), findsOneWidget);
    expect(find.text('تفاصيل'), findsNothing);
  });
}
