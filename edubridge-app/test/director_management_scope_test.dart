import 'dart:async';

import 'package:edubridge_app/screens/school_directors/director_assignment_actions.dart';
import 'package:edubridge_app/screens/school_directors/school_directors_controller.dart';
import 'package:edubridge_app/screens/school_directors/school_directors_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'school_directors_fakes.dart';
import 'curriculum_ui_support.dart' show resumeCurriculum;
import 'school_directors_screen_test.dart' show host, chooseSchool, openEditor, fill;

Future<void> acceptDate(WidgetTester tester) async {
  final button = find.descendant(of: find.byType(DatePickerDialog), matching: find.byType(TextButton)).last;
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      void viewport(WidgetTester tester) {
        tester.view.physicalSize = Size(width, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }

      testWidgets('director directory resets on gateway replacement $language $width', (tester) async {
        viewport(tester);
        final first = FakeSchoolDirectors();
        final second = FakeSchoolDirectors()..schoolResults = [directorSchoolB];
        await tester.pumpWidget(host(SchoolDirectorsScreen(gateway: first), language, scale: 2));
        await tester.pumpAndSettle();
        await chooseSchool(tester);
        expect(find.byKey(const ValueKey('director-add')), findsOneWidget);
        await tester.pumpWidget(host(SchoolDirectorsScreen(gateway: second), language, scale: 2));
        await tester.pumpAndSettle();
        final chooser = tester.widget<DropdownButtonFormField<int>>(find.byType(DropdownButtonFormField<int>));
        expect(chooser.items!.map((item) => item.value), [20]);
        expect(find.byKey(const ValueKey('director-add')), findsNothing);
        expect(first.writes, 0);
        expect(second.writes, 0);
        expect(tester.takeException(), isNull);
      });

      for (final end in [false, true]) {
        for (final refreshAt in ['date', 'confirmation', 'none']) {
          testWidgets('director ${end ? 'end' : 'assign'} refresh=$refreshAt $language $width', (tester) async {
            viewport(tester);
            final gateway = FakeSchoolDirectors();
            final controller = SchoolDirectorsController(gateway);
            addTearDown(controller.dispose);
            await controller.initialize();
            await controller.select(directorSchoolA);
            await tester.pumpWidget(host(Builder(builder: (context) => Scaffold(body: TextButton(
              onPressed: () {
                if (end) {
                  endSchoolDirector(context, controller, controller.directory!.current!);
                } else {
                  assignSchoolDirector(context, controller, directorProfile);
                }
              }, child: const Text('Open action')))), language, scale: 2));
            await tester.tap(find.text('Open action'));
            await tester.pumpAndSettle();
            if (refreshAt == 'date') await controller.reload();
            await acceptDate(tester);
            if (refreshAt == 'date') {
              expect(find.byType(AlertDialog), findsNothing);
            } else {
              expect(find.byType(AlertDialog), findsOneWidget);
              if (refreshAt == 'confirmation') await controller.reload();
              final confirm = find.descendant(of: find.byType(AlertDialog), matching: find.byType(FilledButton));
              await tester.ensureVisible(confirm);
              await tester.pumpAndSettle();
              await tester.tap(confirm);
              await tester.pumpAndSettle();
            }
            expect(gateway.writes, refreshAt == 'none' ? 1 : 0);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

  testWidgets('resume refreshes selected director directory without writes', (tester) async {
    final gateway = FakeSchoolDirectors();
    await tester.pumpWidget(host(SchoolDirectorsScreen(gateway: gateway), 'en'));
    await tester.pumpAndSettle();
    await chooseSchool(tester);
    final reads = gateway.reads;
    await resumeCurriculum(tester);
    expect(gateway.reads, reads + 1);
    expect(gateway.writes, 0);
  });

  testWidgets('back cannot hide pending director profile save', (tester) async {
    final gate = Completer<void>();
    final gateway = FakeSchoolDirectors()..pendingWrite = gate;
    await tester.pumpWidget(host(SchoolDirectorsScreen(gateway: gateway), 'en'));
    await tester.pumpAndSettle();
    await chooseSchool(tester);
    await openEditor(tester);
    await fill(tester);
    await tester.tap(find.byKey(const ValueKey('director-save')));
    await tester.pump();
    await tester.pageBack();
    await tester.pump();
    expect(find.byKey(const ValueKey('director-save')), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(gateway.writes, 1);
    expect(find.byKey(const ValueKey('director-saved')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
