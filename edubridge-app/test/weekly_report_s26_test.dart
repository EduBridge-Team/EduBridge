import 'dart:convert';
import 'package:edubridge_app/screens/weekly_report_screen.dart';
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
    'learning_support_meetings_attended': 1,
    'learning_support_meetings_scheduled': 2,
    'specialist_notes': 'تحسن في القراءة\nالتوصيات: تدريب يومي\nملاءمة الخطة: مناسبة\nتقييم التفاعل: 3/5',
    'concerns': <String>[],
  };

  testWidgets('S26 shows real report sections and keeps historical week selection', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 1050));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final paths = <Uri>[];
    await http.runWithClient(() async {
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: WeeklyReportScreen(
          childId: 7, childName: 'محمود', specialistS26: true)));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(find.text('تقرير محمود الأسبوعي'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
      expect(find.text('تحسن في القراءة'), findsOneWidget);
      expect(find.text('تدريب يومي'), findsOneWidget);
      expect(find.text('مناسبة'), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('لا يوجد'), findsOneWidget);
      expect(tester.getCenter(find.text('الدروس')).dx,
        greaterThan(tester.getCenter(find.text('الواجبات')).dx));
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('s26-week')));
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('الأسبوع الذي يبدأ في 2026-10-05').last);
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(paths.any((uri) => uri.queryParameters['week_start'] == '2026-10-05'), isTrue);
      expect(tester.takeException(), isNull);
    }, () => MockClient((request) async {
      paths.add(request.url);
      final isHistory = request.url.path.endsWith('/child/7');
      return http.Response(jsonEncode(isHistory
        ? {'reports': [{...report, 'week_start': '2026-10-05', 'week_end': '2026-10-11'}]}
        : {'report': report}), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
    }));
  });
}
