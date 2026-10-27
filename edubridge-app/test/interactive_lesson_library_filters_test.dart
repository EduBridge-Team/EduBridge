import 'package:edubridge_app/models/interactive_lesson.dart';
import 'package:edubridge_app/screens/interactive_lesson/interactive_lesson_starter_library.dart';
import 'package:edubridge_app/services/interactive_lesson_starter_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStarterRepository extends InteractiveLessonStarterRepository {
  const _FakeStarterRepository();

  @override
  Future<InteractiveLessonCatalog> load() async => const InteractiveLessonCatalog(
    schemaVersion: '1.0.0',
    locale: 'ar-PS',
    templates: [
      InteractiveLesson(id: 'a', subject: 'arabic', title: 'حرف الألف',
        objective: 'تمييز الحروف', steps: [LessonExplanation('a1', 'ألف')]),
      InteractiveLesson(id: 'm', subject: 'math', title: 'العد',
        objective: 'الأعداد من 1 إلى 5', steps: [LessonExplanation('m1', 'العد')]),
    ],
  );
}

void main() {
  testWidgets('filters starter templates by subject and text', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: InteractiveLessonStarterLibrary(repository: _FakeStarterRepository()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('حرف الألف'), findsOneWidget);
    expect(find.text('العد'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('search-interactive-lessons')), 'الألف');
    await tester.pumpAndSettle();
    expect(find.text('حرف الألف'), findsOneWidget);
    expect(find.text('العد'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('search-interactive-lessons')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filter-interactive-lessons-subject')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الرياضيات').last);
    await tester.pumpAndSettle();
    expect(find.text('حرف الألف'), findsNothing);
    expect(find.text('العد'), findsOneWidget);
  });
}
