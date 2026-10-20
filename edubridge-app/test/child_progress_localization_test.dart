import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/child_progress_screen.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _response(Object data, [int code = 200]) => http.Response(jsonEncode(data), code,
  headers: {'content-type': 'application/json; charset=utf-8'});
MockClient _client({bool empty = false, bool complete = false, bool Function()? failed,
  bool connection = false}) => MockClient((request) async {
  expect(request.method, 'GET');
  if (request.url.path.endsWith('/engagement')) return _response({'stars': 12});
  if (failed?.call() == true) {
    if (connection) throw StateError('Offline');
    return _response({}, 500);
  }
  if (request.url.path.endsWith('/summary')) {
    return _response({'summary': empty ? {} : {
      'done': complete ? 6 : 4, 'in_progress': complete ? 0 : 1,
      'not_started': complete ? 0 : 1, 'avg_score': 90,
    }});
  }
  expect(request.url.path.endsWith('/progress/child/7'), isTrue);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: (now.weekday + 1) % 7));
  return _response({'progress': empty ? [] : [
    for (var i = 0; i < 6; i++) {
      'lesson_id': i + 1, 'lesson_title': 'درس المعلم الأصلي ${i + 1}',
      'status': i < 4 ? 'done' : i == 4 ? 'in_progress' : 'not_started',
      'score': i == 5 ? null : 90,
      'completed_at': start.add(Duration(days: i < 2 ? 0 : i == 2 ? 1 : i == 3 ? -1 : 2, hours: 12)).toIso8601String(),
    },
  ]});
});
const _screen = ChildProgressScreen(childId: 7, childName: 'محمود');
Future<void> _mount(WidgetTester tester, Widget screen, String language, {double scale = 1}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.runAsync(() async {
    await tester.pumpWidget(MaterialApp(locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale)), child: child!), home: screen));
    for (var frame = 0; frame < 3; frame++) {
      await Future<void>.delayed(Duration.zero);
      await tester.pump();
    }
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
Future<void> _tap(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 180, scrollable: find.byType(Scrollable).first);
  }
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(target.hitTestable());
    await tester.pump();
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 160, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'userId': 1, 'role': 'specialist'});
    FlutterSecureStorage.setMockInitialValues({});
    AccessibilityService.instance.resetSession();
    await AccessibilityService.instance.load();
  });
  tearDown(AccessibilityService.instance.resetSession);
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$language progress at $scale preserves summary, weekly counts and badge thresholds', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await http.runWithClient(() async {
          await _mount(tester, _screen, language, scale: scale);
          expect(find.text(strings.childProgressFor('محمود')), findsOneWidget);
          expect(find.text(strings.childProgressPercent('محمود', '67')), findsOneWidget);
          expect(find.text(strings.childProgressCompletedCount('4', '6')), findsOneWidget);
          expect(tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).value, closeTo(4 / 6, .00001));
          final statisticCards = find.byWidgetPredicate((widget) => widget is Container && widget.constraints?.maxHeight == 127);
          expect(statisticCards, findsNWidgets(4));
          final statisticOffsets = List.generate(4, (i) => tester.getTopLeft(statisticCards.at(i)).dy);
          expect(statisticOffsets, everyElement(statisticOffsets.first));
          await _reveal(tester, find.text(strings.childProgressWeekly));
          for (final label in [strings.childProgressWeekday0, strings.childProgressWeekday1,
            strings.childProgressWeekday2, strings.childProgressWeekday3,
            strings.childProgressWeekday4, strings.childProgressWeekday5, strings.childProgressWeekday6]) {
            expect(find.text(label), findsOneWidget);
          }
          final bars = tester.widgetList<Container>(find.byType(Container))
            .where((widget) => widget.constraints?.maxWidth == 20 && widget.decoration is BoxDecoration)
            .where((widget) => (widget.decoration as BoxDecoration).color != const Color(0xFFEEF5FA))
            .map((widget) => widget.constraints!.maxHeight).toList();
          expect(bars, containsAll([67.0, 38.5]));
          expect(bars, hasLength(2));
          await _reveal(tester, find.text(strings.childProgressFirstBadge));
          expect(find.text(strings.childProgressStars(12)), findsOneWidget);
          expect(find.text(strings.childProgressPersistenceBadge), findsOneWidget);
          expect(find.text(strings.childProgressChampionBadge), findsOneWidget);
          expect(find.text(strings.childProgressEarned), findsNWidgets(2));
          final badgeCards = find.byWidgetPredicate((widget) => widget is Container && widget.constraints?.maxHeight == 179);
          expect(badgeCards, findsNWidgets(3));
          final badgeOffsets = List.generate(3, (i) => tester.getTopLeft(badgeCards.at(i)).dy);
          expect(badgeOffsets, everyElement(badgeOffsets.first));
          expect(tester.widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
            .map((widget) => widget.value), containsAll([1.0, 1.0, 4 / 9]));
          for (var i = 1; i <= 6; i++) {
            final title = find.text('درس المعلم الأصلي $i');
            await _reveal(tester, title);
            expect(title, findsOneWidget);
            if (i == 5) {
              expect(find.text(strings.childProgressStatusScore(strings.inProgress, '90')), findsOneWidget);
            }
          }
          expect(find.text(strings.studentLessonNotStarted), findsWidgets);
          await _reveal(tester, find.text(strings.childProgressSuggest));
          expect(find.text(strings.childProgressSuggest), findsOneWidget);
        }, () => _client());
      });
      testWidgets('$language empty progress at $scale keeps zero values and unearned rewards', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await http.runWithClient(() async {
          await _mount(tester, _screen, language, scale: scale);
          expect(find.text(strings.childProgressNotBegun('محمود')), findsOneWidget);
          expect(find.text(strings.childProgressCompletedCount('0', '0')), findsOneWidget);
          expect(tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).value, 0);
          await _reveal(tester, find.text(strings.childProgressNoWeekly));
          expect(find.text(strings.childProgressNoWeekly), findsOneWidget);
          await _reveal(tester, find.text(strings.childProgressFirstBadge));
          expect(find.text(strings.childProgressEarned), findsNothing);
          expect(tester.widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
            .map((widget) => widget.value), everyElement(0));
          await _reveal(tester, find.text(strings.childProgressEmpty));
          expect(find.text(strings.childProgressEmpty), findsOneWidget);
        }, () => _client(empty: true));
      });
    }
    testWidgets('$language all lessons complete keeps the 100 percent summary', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      await http.runWithClient(() async {
        await _mount(tester, _screen, language);
        expect(find.text(strings.childProgressAllDone('محمود')), findsOneWidget);
        expect(find.text(strings.childProgressCompletedCount('6', '6')), findsOneWidget);
        expect(tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).value, 1);
      }, () => _client(complete: true));
    });
    for (final connection in [false, true]) {
      testWidgets('$language error connection=$connection can retry', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        var failed = true;
        await http.runWithClient(() async {
          await _mount(tester, _screen, language);
          expect(find.text(connection ? strings.connectionFailed : strings.childProgressFetchError), findsOneWidget);
          failed = false;
          await _tap(tester, find.text(strings.retryAction));
          expect(find.text(strings.childProgressPercent('محمود', '67')), findsOneWidget);
        }, () => _client(failed: () => failed, connection: connection));
      });
    }
  }
}
