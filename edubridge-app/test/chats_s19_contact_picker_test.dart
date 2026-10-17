import 'package:edubridge_app/screens/chats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('S19 modal shows real contacts and creates no sample contact',
      (tester) async {
    int? selectedId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => SpecialistContactPickerDialog(
                  users: const [
                    {'id': 7, 'name': 'مستخدم أول', 'role': 'parent'},
                    {'id': 8, 'name': 'مستخدم ثان', 'role': 'teacher'},
                  ],
                  onSelect: (user) {
                    selectedId = user['id'] as int;
                    Navigator.of(context).pop();
                  },
                ),
              ),
              child: const Text('فتح القائمة'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح القائمة'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('فريق التواصل'), findsOneWidget);
    expect(find.text('مستخدم أول'), findsOneWidget);
    expect(find.text('مستخدم ثان'), findsOneWidget);
    expect(find.text('أبو محمد'), findsNothing);
    expect(find.byKey(const ValueKey('s19_cancel')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('s19_contact_7')));
    await tester.pumpAndSettle();
    expect(selectedId, 7);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('S19 empty contact list can be cancelled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => SpecialistContactPickerDialog(
                  users: const [],
                  onSelect: (_) {},
                ),
              ),
              child: const Text('فتح القائمة'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('فتح القائمة'));
    await tester.pumpAndSettle();
    expect(find.text('لا يوجد مستخدمون متاحون'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('s19_cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });
}
