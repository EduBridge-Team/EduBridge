import 'package:edubridge_app/screens/case_discussion/case_discussion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('S21 opens as a centered RTL modal and preserves actions',
      (tester) async {
    final topic = TextEditingController();
    final description = TextEditingController();
    addTearDown(topic.dispose);
    addTearDown(description.dispose);
    var createCount = 0;
    var cancelCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => NewCaseStudyDialogS21(
                  children: const [],
                  team: const [],
                  selectedChildId: null,
                  selectedParticipants: const <int>{8},
                  myUserId: 8,
                  topicController: topic,
                  descriptionController: description,
                  loading: false,
                  saving: false,
                  error: null,
                  onChildSelected: (_) {},
                  onParticipantToggled: (_) {},
                  onSave: () => createCount++,
                  onCancel: () {
                    cancelCount++;
                    Navigator.of(context).pop();
                  },
                  onRetry: () {},
                ),
              ),
              child: const Text('فتح الدراسة'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح الدراسة'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('دراسة حالة جديدة'), findsOneWidget);
    expect(find.byKey(const ValueKey('s21_child_selector')), findsOneWidget);
    expect(find.byKey(const ValueKey('s21_topic')), findsOneWidget);
    expect(find.byKey(const ValueKey('s21_description')), findsOneWidget);
    // The current user is already a member, but 0 additional
    // participants should show until others are selected.
    expect(find.text('المشاركون من الفريق (0)'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
    expect(find.text('إنشاء'), findsOneWidget);
    expect(tester.getCenter(find.text('إلغاء')).dx,
      greaterThan(tester.getCenter(find.text('إنشاء')).dx));

    await tester.tap(find.byKey(const ValueKey('s21_create')));
    await tester.pump();
    expect(createCount, 1);
    await tester.tap(find.byKey(const ValueKey('s21_cancel')));
    await tester.pumpAndSettle();
    expect(cancelCount, 1);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('S21 counts only extra team members', (tester) async {
    final topic = TextEditingController();
    final description = TextEditingController();
    addTearDown(topic.dispose);
    addTearDown(description.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewCaseStudyDialogS21(
            children: const [
              {'id': 12, 'name': 'طفل تجريبي'},
            ],
            team: const [
              {'id': 8, 'name': 'صاحب الحساب', 'role': 'specialist'},
              {'id': 9, 'name': 'معلّم الفريق', 'role': 'teacher'},
            ],
            selectedChildId: 12,
            selectedParticipants: const <int>{8, 9},
            myUserId: 8,
            topicController: topic,
            descriptionController: description,
            loading: false,
            saving: false,
            error: null,
            onChildSelected: (_) {},
            onParticipantToggled: (_) {},
            onSave: () {},
            onCancel: () {},
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('المشاركون من الفريق (1)'), findsOneWidget);
    expect(find.text('معلّم الفريق'), findsOneWidget);
    expect(find.text('صاحب الحساب'), findsNothing);
  });
}
