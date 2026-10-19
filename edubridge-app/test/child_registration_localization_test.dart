import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/add_child/add_child_screen.dart';
import 'package:edubridge_app/widgets/disability/disability_catalog.dart';
import 'package:edubridge_app/widgets/disability/disability_display.dart';
import 'package:edubridge_app/widgets/disability/disability_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget screen, Locale locale, {double scale = 1, double keyboard = 0}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale),
      viewInsets: EdgeInsets.only(bottom: keyboard)), child: child!),
  home: screen,
);
Future<void> _narrow(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(320, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}
Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}
Future<void> _picker(WidgetTester tester, String language, bool s30,
    ValueChanged<String?> done, {double scale = 1, double keyboard = 0}) async {
  await _narrow(tester);
  await tester.pumpWidget(_host(Scaffold(body: Builder(builder: (context) => TextButton(
    onPressed: () async => done(await showModalBottomSheet<String>(
      context: context, isScrollControlled: true,
      builder: (_) => DisabilityPickerSheet(figmaS30: s30))),
    child: const Text('Open')))), Locale(language), scale: scale, keyboard: keyboard));
  await _tap(tester, find.text('Open'));
}

void main() {
  test('all known catalog values have display labels without changing identifiers', () async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final values = [...kAllDisabilityTypes, ...kDisabilityCategories.map((c) => c.label)];
    for (final value in values) {
      expect(DisabilityDisplay.label(value, ar), value);
      final english = DisabilityDisplay.label(value, en);
      expect(english, isNot(value), reason: value);
      expect(english.contains(RegExp('[ء-ي]')), isFalse, reason: value);
      expect(DisabilityDisplay.matches(value, english.toUpperCase(), en), isTrue);
      expect(DisabilityDisplay.matches(value, value, en), isTrue);
    }
    expect(DisabilityDisplay.label('وصف خاص كتبه المختص', en), 'وصف خاص كتبه المختص');
    expect(isKnownDisability('Color blindness'), isFalse);
    expect(disabilityTypeForCategory('عمى الألوان').name, 'colorBlindness');
  });

  for (final language in ['ar', 'en']) {
    for (final s30 in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$language picker s30=$s30 scale=$scale searches and returns canonical value', (tester) async {
          String? result;
          final s = await AppLocalizations.delegate.load(Locale(language));
          await _picker(tester, language, s30, (value) => result = value,
            scale: scale, keyboard: 280);
          expect(find.text(s.selectDisability), findsOneWidget);
          expect(Directionality.of(tester.element(find.byType(DisabilityPickerSheet))),
            language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
          await tester.enterText(find.byType(TextField), language == 'en' ? 'COLOR BLIND' : 'عمى الألوان');
          await tester.pumpAndSettle();
          await _tap(tester, find.text(s.disabilityColorBlindness));
          expect(result, 'عمى الألوان');
          expect(tester.takeException(), isNull);
        });
      }
      for (final value in ['أخرى', 'بدون تكييف']) {
        testWidgets('$language picker s30=$s30 finds special option $value', (tester) async {
          final s = await AppLocalizations.delegate.load(Locale(language));
          String? result;
          await _picker(tester, language, s30, (value) => result = value);
          await tester.enterText(find.byType(TextField), 'zzzz');
          await tester.pumpAndSettle();
          expect(find.text(s.noDisabilitySearchResults), findsOneWidget);
          await _tap(tester, find.byTooltip(s.clearSearch));
          expect(find.text(s.disabilityVisual), findsOneWidget);
          final label = DisabilityDisplay.label(value, s);
          await tester.enterText(find.byType(TextField), label);
          await tester.pumpAndSettle();
          await _tap(tester, find.text(label));
          expect(result, value);
          expect(tester.takeException(), isNull);
        });
      }
    }
    for (final scale in [1.0, 2.0]) {
      testWidgets('$language registration scale=$scale validates required fields and document layout', (tester) async {
        await _narrow(tester);
        final s = await AppLocalizations.delegate.load(Locale(language));
        await tester.pumpWidget(_host(const AddChildScreen(), Locale(language), scale: scale));
        await tester.pumpAndSettle();
        expect(find.text(s.addNewChild), findsOneWidget);
        await _tap(tester, find.text(s.submitForReview));
        expect(find.text(s.nameRequired), findsOneWidget);
        expect(find.text(s.ageRequired), findsOneWidget);
        expect(find.text(s.nationalIdRequired), findsNWidgets(2));
        expect(find.text(s.disabilityDescriptionRequired), findsOneWidget);
        expect(find.text(s.specialNeedsRequired), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('changing language keeps child draft and updates existing validation', (tester) async {
    final language = ValueNotifier(const Locale('ar'));
    addTearDown(language.dispose);
    await tester.pumpWidget(ValueListenableBuilder<Locale>(valueListenable: language,
      builder: (_, locale, __) => _host(const AddChildScreen(), locale)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'ليان');
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    await _tap(tester, find.text(ar.submitForReview));
    expect(find.text(ar.ageRequired), findsOneWidget);
    language.value = const Locale('en');
    await tester.pumpAndSettle();
    expect(find.text(en.ageRequired), findsOneWidget);
    expect(find.text(ar.ageRequired), findsNothing);
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text, 'ليان');
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration displays a translated choice but still requires identity documents', (tester) async {
    final s = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(_host(const AddChildScreen(), const Locale('en')));
    await tester.pumpAndSettle();
    final values = ['ليان', '9', '123456789', '987654321', 'وصف كتبه المختص',
      'احتياجات خاصة', 'تعلم بصري', 'قراءة', 'كتابة'];
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(find.byType(TextFormField).at(i), values[i]);
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _tap(tester, find.text(s.tapToChoose));
    await tester.enterText(find.byType(TextField).last, 'Color blindness');
    await tester.pumpAndSettle();
    await _tap(tester, find.text(s.disabilityColorBlindness));
    expect(find.text(s.disabilityColorBlindness), findsOneWidget);
    await _tap(tester, find.text(s.submitForReview));
    expect(find.text(s.guardianPhotoRequired), findsOneWidget);
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text, 'ليان');
    expect(tester.takeException(), isNull);
  });

  testWidgets('English picker also accepts Arabic search and dismissing keeps the draft selection', (tester) async {
    var dismissed = false;
    String? result;
    await _picker(tester, 'en', true, (value) { dismissed = true; result = value; });
    await tester.enterText(find.byType(TextField), 'عمى الألوان');
    await tester.pumpAndSettle();
    expect(find.text('Color blindness'), findsOneWidget);
    await _tap(tester, find.byTooltip('Close'));
    expect(dismissed, isTrue);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}
