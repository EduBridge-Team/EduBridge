import 'package:edubridge_app/screens/institution_attendance/institution_attendance_create_screen.dart';
import 'package:edubridge_app/screens/institution_attendance/institution_attendance_mark_screen.dart';
import 'package:edubridge_app/screens/institution_enrollment/institution_enrollment_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart';
import 'institution_attendance_fixture.dart';
import 'institution_attendance_write_screens_test.dart' show attendanceText;
import 'institution_enrollment_history_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      void viewport(WidgetTester tester) {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }

      testWidgets('attendance create discards previous writer draft $language $width', (tester) async {
        viewport(tester);
        final first = InstitutionAttendanceFixture(), second = InstitutionAttendanceFixture();
        final firstWriter = first.repository, secondWriter = second.repository;
        await tester.pumpWidget(curriculumHost(InstitutionAttendanceCreateScreen(writer: firstWriter,
          initialDate: DateTime(2026, 10, 26)), language));
        await tester.pumpAndSettle();
        await attendanceText(tester, 'attendance-create-note', 'old draft');
        await tester.pumpWidget(curriculumHost(InstitutionAttendanceCreateScreen(writer: secondWriter,
          initialDate: DateTime(2026, 10, 27)), language));
        await tester.pumpAndSettle();
        final note = tester.widget<TextFormField>(find.byKey(const ValueKey('attendance-create-note')));
        expect(note.controller!.text, isEmpty);
        expect(second.paths, isNotEmpty);
        expect(first.posts, isEmpty);
        expect(second.posts, isEmpty);
        expect(tester.takeException(), isNull);
      });

      testWidgets('attendance editor reloads replacement writer $language $width', (tester) async {
        viewport(tester);
        final first = InstitutionAttendanceFixture(), second = InstitutionAttendanceFixture();
        second.records[0]['note'] = 'replacement record';
        final firstWriter = first.repository, secondWriter = second.repository;
        await tester.pumpWidget(curriculumHost(InstitutionAttendanceMarkScreen(writer: firstWriter,
          sessionId: 60, date: DateTime(2026, 10, 26)), language));
        await tester.pumpAndSettle();
        await attendanceText(tester, 'attendance-note-9', 'old draft');
        await tester.pumpWidget(curriculumHost(InstitutionAttendanceMarkScreen(writer: secondWriter,
          sessionId: 60, date: DateTime(2026, 10, 26)), language));
        await tester.pumpAndSettle();
        final note = tester.widget<TextFormField>(find.byKey(const ValueKey('attendance-note-9')));
        expect(note.controller!.text, 'replacement record');
        expect(first.puts, isEmpty);
        expect(second.puts, isEmpty);
        expect(tester.takeException(), isNull);
      });

      for (final transfer in [false, true]) {
        testWidgets('refresh invalidates ${transfer ? 'transfer' : 'withdrawal'} dialog $language $width', (tester) async {
          viewport(tester);
          final f = InstitutionHistoryFixture()..addTarget();
          final gateway = f.repository;
          await tester.pumpWidget(curriculumHost(InstitutionEnrollmentHistoryScreen(gateway: gateway), language));
          await tester.pumpAndSettle();
          await tapCurriculum(tester, transfer ? 'institution-transfer-2' : 'institution-withdraw-2');
          if (transfer) await tapCurriculum(tester, 'transfer-target-31');
          await resumeCurriculum(tester);
          await tapCurriculum(tester, transfer ? 'confirm-institution-transfer' : 'confirm-institution-withdrawal');
          expect(f.writes, isEmpty);
          expect(f.patches, isEmpty);
          expect(find.byType(AlertDialog), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
