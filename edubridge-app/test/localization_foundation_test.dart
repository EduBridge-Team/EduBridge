import 'dart:convert';
import 'dart:io';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Arabic and English catalogs have matching non-empty messages and placeholders', () {
    Map<String, dynamic> catalog(String locale) => jsonDecode(
      File('lib/l10n/app_$locale.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final arabic = catalog('ar');
    final english = catalog('en');
    Set<String> keys(Map<String, dynamic> data) =>
        data.keys.where((key) => !key.startsWith('@')).toSet();
    expect(keys(arabic), keys(english));
    for (final key in keys(arabic)) {
      expect((arabic[key] as String).trim(), isNotEmpty, reason: key);
      expect((english[key] as String).trim(), isNotEmpty, reason: key);
      final arMetadata = arabic['@$key'] as Map<String, dynamic>;
      final enMetadata = english['@$key'] as Map<String, dynamic>;
      expect(arMetadata['description'], isNotEmpty, reason: key);
      expect(enMetadata['placeholders'], arMetadata['placeholders'], reason: key);
    }
  });

  test('generated messages support Arabic plural forms and English counts', () async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(ar.activityCount(0), 'لا توجد أنشطة');
    expect(ar.activityCount(1), 'نشاط واحد');
    expect(ar.activityCount(2), 'نشاطان');
    expect(ar.activityCount(3), '3 أنشطة');
    expect(ar.activityCount(11), '11 نشاطًا');
    expect(ar.activityCount(100), '100 نشاط');
    expect(en.activityCount(0), 'No activities');
    expect(en.activityCount(1), 'One activity');
    expect(en.activityCount(3), '3 activities');
    expect(en.arabicLanguage, 'العربية');
    expect(ar.englishLanguage, 'English');
  });

  for (final language in ['ar', 'en']) {
    testWidgets('$language provides app, Material and direction delegates', (tester) async {
      late BuildContext contentContext;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(builder: (context) {
          contentContext = context;
          return Scaffold(body: Text(AppLocalizations.of(context).language));
        }),
      ));
      await tester.pumpAndSettle();
      expect(find.text(language == 'ar' ? 'اللغة' : 'Language'), findsOneWidget);
      expect(Directionality.of(contentContext),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      expect(MaterialLocalizations.of(contentContext).cancelButtonLabel,
          language == 'ar' ? 'إلغاء' : 'Cancel');
      expect(tester.takeException(), isNull);
    });
  }
}
