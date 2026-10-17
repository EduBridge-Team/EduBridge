import 'package:edubridge_app/screens/case_discussion/case_discussion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('S21 case study dialog renders centered RTL fields and actions',
      (tester) async {
    var created = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => CaseDiscussionNewS21Dialog(
                  fields: const Column(
                    children: [
                      TextField(
                        key: ValueKey('test_child'),
                        decoration: InputDecoration(hintText: 'الطفل *'),
                      ),
                      TextField(
                        key: ValueKey('test_topic'),
                        decoration: InputDecoration(hintText: 'موضوع الدراسة *'),
                      ),
                      TextField(
                        key: ValueKey('test_desc'),
                        decoration: InputDecoration(
                          hintText: 'وصف الحالة (اختياري)'),
                      ),
                      Text('المشاركون من الفريق (0)'),
                    ],
                  ),
                  onCancel: () => Navigator.of(context).pop(),
                  onCreate: () => created++,
                ),
              ),
              child: const Text('فتح النافذة'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح النافذة'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('دراسة حالة جديدة'), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.byKey(const ValueKey('test_child')), findsOneWidget);
    expect(find.byKey(const ValueKey('test_topic')), findsOneWidget);
    expect(find.byKey(const ValueKey('test_desc')), findsOneWidget);
    expect(find.text('المشاركون من الفريق (0)'), findsOneWidget);

    final cancel = tester.getCenter(find.byKey(const ValueKey('s21_cancel')));
    final create = tester.getCenter(find.byKey(const ValueKey('s21_create')));
    expect(cancel.dx, greaterThan(create.dx));

    await tester.tap(find.byKey(const ValueKey('s21_create')));
    await tester.pump();
    expect(created, 1);

    await tester.tap(find.byKey(const ValueKey('s21_cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('S21 disables creation while loading and shows loading feedback',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CaseDiscussionNewS21Dialog(
            fields: SizedBox.shrink(),
            loading: true,
            onCancel: _noop,
            onCreate: _noop,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final submit = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'إنشاء'),
    );
    expect(submit.onPressed, isNull);
  });
}

void _noop() {}
