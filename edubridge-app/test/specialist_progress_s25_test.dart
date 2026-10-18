import 'dart:convert';

import 'package:edubridge_app/screens/create_specialist_progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  final report = {
    'id': 1, 'child_id': 7, 'child_name': 'محمود',
    'week_start': '2026-10-12', 'week_end': '2026-10-18',
    'generated_at': '2026-10-18', 'progress_percentage': 25,
    'lessons_completed': 1, 'lessons_total': 4,
    'homework_submitted': 2, 'homework_assigned': 3,
    'teacher_notes': 'يتحسن في القراءة',
  };

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // TokenStore serializes secure-storage work across calls. Run platform
    // futures outside the per-test fake clock before settling UI animations.
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(
        home: CreateSpecialistProgressScreen(childId: 7, childName: 'محمود'),
      ));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  testWidgets('S25 uses real report values and RTL reference ordering', (tester) async {
    await http.runWithClient(() async {
      await open(tester);
      expect(find.text('تقييم تقدّم محمود'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('ملاحظات المعلم: يتحسن في القراءة'), findsOneWidget);
      expect(tester.getCenter(find.text('الإنجاز')).dx,
          greaterThan(tester.getCenter(find.text('الدروس')).dx));
      expect(tester.getCenter(find.text('تحتاج تعديل')).dx,
          greaterThan(tester.getCenter(find.text('مناسبة')).dx));
      expect(tester.getCenter(find.byTooltip('ممتازة')).dx,
          greaterThan(tester.getCenter(find.byTooltip('ضعيفة جدًا')).dx));
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async => http.Response(
      jsonEncode({'report': report}), 200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    )));
  });

  testWidgets('S25 validates notes and preserves plan and rating payload on retry', (tester) async {
    final saved = <Map<String, dynamic>>[];
    await http.runWithClient(() async {
      await open(tester);
      await tester.ensureVisible(find.text('حفظ التقييم'));
      await tester.runAsync(() async {
        await tester.tap(find.text('حفظ التقييم'));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(saved, isEmpty);
      expect(find.text('مطلوب'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'تحسن ملحوظ');
      await tester.enterText(find.byType(TextFormField).at(1), 'متابعة القراءة');
      await tester.ensureVisible(find.text('تحتاج تعديل'));
      await tester.tap(find.text('تحتاج تعديل'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(3));
      await tester.enterText(find.byType(TextFormField).at(2), 'زيادة التدريب');
      await tester.ensureVisible(find.byTooltip('ممتازة'));
      await tester.tap(find.byTooltip('ممتازة'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('حفظ التقييم'));
      await tester.runAsync(() async {
        await tester.tap(find.text('حفظ التقييم'));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(saved.single, {
        'child_id': 7, 'specialist_notes': 'تحسن ملحوظ',
        'recommendations': 'متابعة القراءة', 'is_plan_appropriate': false,
        'plan_evaluation': 'زيادة التدريب', 'mood_rating': 5,
      });
      expect(find.text('فشل الحفظ'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('حفظ التقييم'));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(saved, hasLength(2));
      expect(saved.last, saved.first);
      expect(tester.takeException(), isNull);
    }, () => MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(jsonEncode({'report': report}), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
      }
      expect(request.url.path, endsWith('/reports/weekly/specialist'));
      saved.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response('{}', 500);
    }));
  });

  testWidgets('S25 missing report keeps independent evaluation available', (tester) async {
    await http.runWithClient(() async {
      await open(tester);
      expect(find.textContaining('لم يكتب المعلم تقريراً'), findsOneWidget);
      expect(find.text('0/4'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('حفظ التقييم'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async => http.Response('{"report":null}', 200)));
  });
}
