import 'package:edubridge_app/screens/child_accessibility/child_accessibility_settings_screen.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('S27 sections open independently and preserve switch callbacks', (tester) async {
    var hearingEnabled = false;
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Directionality(
      textDirection: TextDirection.rtl,
      child: StatefulBuilder(builder: (context, update) {
        final c = JisrColors.of(context);
        return Scaffold(
          appBar: buildChildSettingsAppBar(context, 'محمود'),
          body: ListView(children: [
            buildInfoBanner(context, c, 'محمود'),
            buildFeatureSection(title: 'ميزات الإعاقات البصرية',
              icon: Icons.visibility, color: Colors.blue, c: c,
              children: [sw('واجهة نصية فقط', 'عرض وصف الصور', false, (_) {})]),
            buildFeatureSection(title: 'ميزات الإعاقات السمعية', initiallyExpanded: false,
              icon: Icons.hearing, color: Colors.blue, c: c,
              children: [sw('ترجمة نصية للفيديوهات', 'الترجمة المتاحة للدرس',
                hearingEnabled, (value) => update(() => hearingEnabled = value))]),
          ]),
        );
      }),
    )));
    await tester.pumpAndSettle();
    expect(find.text('إعدادات محمود'), findsOneWidget);
    expect(find.text('واجهة نصية فقط').hitTestable(), findsOneWidget);
    expect(find.text('ترجمة نصية للفيديوهات').hitTestable(), findsNothing);
    await tester.tap(find.text('ميزات الإعاقات السمعية'));
    await tester.pumpAndSettle();
    expect(find.text('واجهة نصية فقط').hitTestable(), findsOneWidget);
    expect(find.text('ترجمة نصية للفيديوهات').hitTestable(), findsOneWidget);
    await tester.tap(find.text('ترجمة نصية للفيديوهات'));
    await tester.pumpAndSettle();
    expect(hearingEnabled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('S27 unavailable switches keep their stored state and cannot change', (tester) async {
    var changes = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: sw(
      'تنبيهات بوميض', 'غير مفعلة حالياً', true, (_) => changes++, enabled: false))));
    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isTrue);
    expect(tile.onChanged, isNull);
    await tester.tap(find.text('تنبيهات بوميض'));
    await tester.pump();
    expect(changes, 0);
  });
}
