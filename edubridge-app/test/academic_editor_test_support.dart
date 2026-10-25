import 'dart:async';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/model/schools/academic_catalog.dart';
import 'package:edubridge_app/screens/academics/academic_controller.dart';
import 'package:edubridge_app/screens/academics/academic_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'academic_filter_fixtures.dart';

class EditorAcademicGateway extends FilterAcademicGateway {
  AcademicDraft? draft;
  int? savedSchool;
  Completer<void>? pending;
  @override
  Future<void> create(int schoolId, AcademicDraft draft) async {
    writes++;
    this.draft = draft;
    savedSchool = schoolId;
    if (pending != null) await pending!.future;
  }
}

Future<void> openAcademicEditor(
  WidgetTester tester,
  AcademicController controller,
  AcademicKind kind, {
  String language = 'en',
  double width = 320,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await controller.reload();
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const ValueKey('open-editor'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AcademicCreateScreen(controller: controller, kind: kind),
              ),
            ),
            child: const Text('Open editor'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-editor')));
  await tester.pumpAndSettle();
}

Future<void> tapEditorKey(WidgetTester tester, String key) async {
  final field = find.byKey(ValueKey(key));
  final target = key == 'academic-year' || key == 'academic-grade'
      ? find.descendant(
          of: field,
          matching: find.byWidgetPredicate(
            (widget) => widget is OutlinedButton,
          ),
        )
      : field;
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> chooseEditorValue(
  WidgetTester tester,
  String key,
  String label,
) async {
  await tapEditorKey(tester, key);
  final target = find.descendant(
    of: find.byType(SimpleDialog),
    matching: find.text(label),
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> chooseEditorDate(
  WidgetTester tester,
  String key,
  DateTime date,
) async {
  await tapEditorKey(tester, key);
  // Exercise the editor's date-picker result without depending on today's month.
  Navigator.of(tester.element(find.byType(DatePickerDialog))).pop(date);
  await tester.pumpAndSettle();
}
