import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget curriculumHost(Widget child, String language) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  ),
  home: child,
);
Future<void> revealCurriculum(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> tapCurriculum(WidgetTester tester, String key) async {
  final field = find.byKey(ValueKey(key));
  final target = key == 'curriculum-year'
      ? find.descendant(
          of: field,
          matching: find.byWidgetPredicate(
            (widget) => widget is OutlinedButton,
          ),
        )
      : field;
  await revealCurriculum(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> chooseCurriculumYear(WidgetTester tester, String label) async {
  await tapCurriculum(tester, 'curriculum-year');
  final target = find.descendant(
    of: find.byType(SimpleDialog),
    matching: find.text(label),
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> curriculumDate(
  WidgetTester tester,
  String key,
  DateTime date,
) async {
  await tapCurriculum(tester, key);
  Navigator.of(tester.element(find.byType(DatePickerDialog))).pop(date);
  await tester.pumpAndSettle();
}

Future<void> resumeCurriculum(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
}
