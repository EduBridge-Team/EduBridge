import 'package:edubridge_app/widgets/teacher_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('teacher navigation shows children lessons and homework', (tester) async {
    SharedPreferences.setMockInitialValues({'role': 'teacher'});
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(bottomNavigationBar: TeacherNavigationBar()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('الأطفال'), findsOneWidget);
    expect(find.text('الدروس'), findsOneWidget);
    expect(find.text('الواجبات'), findsOneWidget);
  });

  testWidgets('specialist navigation shows students and lessons', (tester) async {
    SharedPreferences.setMockInitialValues({'role': 'specialist'});
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(bottomNavigationBar: TeacherNavigationBar()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('الطلاب'), findsOneWidget);
    expect(find.text('الدروس'), findsOneWidget);
    expect(find.text('التقدم'), findsNothing);
  });

  testWidgets('shared screens do not show teacher destinations to parents', (tester) async {
    SharedPreferences.setMockInitialValues({'role': 'parent'});
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(bottomNavigationBar: TeacherNavigationBar()),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
  });
}
