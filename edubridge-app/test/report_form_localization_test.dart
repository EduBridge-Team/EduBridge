import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/create_weekly_report_screen.dart';
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
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final specialist in [false, true]) {
        testWidgets('$language report form specialist=$specialist scale=$scale', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(360, 800);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          await tester.binding.setSurfaceSize(const Size(360, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final strings = await AppLocalizations.delegate.load(Locale(language));
          await http.runWithClient(() async {
            await tester.runAsync(() async {
              await tester.pumpWidget(MaterialApp(
                locale: Locale(language),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!),
                home: specialist
                    ? const CreateSpecialistProgressScreen(childId: 7, childName: 'محمود', initialNotes: 'ملاحظة أصلية')
                    : const CreateWeeklyReportScreen(childId: 7, childName: 'محمود'),
              ));
              await Future<void>.delayed(Duration.zero);
            });
            await tester.pumpAndSettle();
            expect(find.text(specialist ? strings.progressEvaluationFor('محمود') : strings.weeklyReportFor('محمود')), findsOneWidget);
            expect(Directionality.of(tester.element(find.byType(Form))), language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
            if (specialist) {
              expect(find.text('ملاحظة أصلية'), findsOneWidget);
              await tester.scrollUntilVisible(find.text(strings.saveEvaluation), 180,
                scrollable: find.byType(Scrollable).first);
            } else {
              await tester.tap(find.text(strings.weeklySaveReport));
              await tester.pumpAndSettle();
              expect(find.text(strings.fieldRequired), findsWidgets);
            }
            expect(tester.takeException(), isNull);
          }, () => MockClient((request) async => http.Response(jsonEncode({'report': null}), 200,
            headers: {'content-type': 'application/json; charset=utf-8'})));
        });
      }
    }
  }
  testWidgets('weekly report keeps authored content and API values in English', (tester) async {
    Map<String, dynamic>? payload;
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: Builder(builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const CreateWeeklyReportScreen(childId: 7, childName: 'محمود'))),
          child: const Text('Open')))),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '4');
      await tester.scrollUntilVisible(find.byType(TextFormField).last, 150,
        scrollable: find.byType(Scrollable).first);
      await tester.enterText(find.byType(TextFormField).last, 'ملاحظة المعلم الأصلية');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Save report'));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(payload?['child_id'], 7);
      expect(payload?['lessons_completed'], 4);
      expect(payload?['progress_percentage'], 50);
      expect(payload?['teacher_notes'], 'ملاحظة المعلم الأصلية');
      expect(payload?['achievements'], isEmpty);
      expect(payload?['concerns'], isEmpty);
      expect(DateTime.tryParse(payload!['week_start'] as String), isNotNull);
      expect(find.text('Open'), findsOneWidget);
    }, () => MockClient((request) async {
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('{}', 201);
    }));
  });

}
