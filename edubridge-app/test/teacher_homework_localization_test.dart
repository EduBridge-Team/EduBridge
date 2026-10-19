import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/create_homework_screen.dart';
import 'package:edubridge_app/screens/teacher_child_details/teacher_child_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _response(Object data, [int status = 200]) => http.Response(jsonEncode(data), status,
  headers: {'content-type': 'application/json; charset=utf-8'});
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
      home: screen));
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
Future<void> _tap(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(target.hitTestable());
    await tester.pump();
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
Future<void> _scrollTo(WidgetTester tester, Finder target) => tester.scrollUntilVisible(
  target.hitTestable(), 140, scrollable: find.byType(Scrollable).first);
Map<String, Object?> _homework(int id, {int? grade, bool submitted = false}) => {
  'id': id, 'title': 'واجب أصلي $id', 'description': 'وصف المعلم الأصلي',
  'due_date': '2030-12-15', 'created_at': '2026-10-01', 'subject': 'مادة أصلية',
  'assigned_child_ids': [7], 'submissions': submitted ? [{
    'id': 42, 'homework_id': id, 'child_id': 7, 'child_name': 'محمود',
    'submitted_at': '2026-10-12T14:30:00', 'text_answer': 'إجابة الطالب الأصلية',
    'grade': grade, 'feedback': grade == null ? null : 'ملاحظة أصلية', 'is_late': false,
  }] : [],
};
MockClient _client({Future<http.Response> Function(http.Request)? write}) => MockClient((request) async {
  if (request.method != 'GET') return write == null ? _response({}, 500) : await write(request);
  if (request.url.path.endsWith('/homeworks')) {
    return _response({'homeworks': [
    _homework(1), _homework(2, submitted: true), _homework(3, submitted: true, grade: 80),
    ]});
  }
  if (request.url.path.endsWith('/lessons')) return _response({'lessons': [{'id': 8, 'title': 'درس المعلم الأصلي'}]});
  if (request.url.path.contains('/progress/')) return _response({'progress': [{'lesson_id': 8, 'status': 'done', 'score': 90, 'completed_at': '2026-10-12'}]});
  return _response({'reports': [], 'report': null, 'discussions': []});
});
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$language create homework validation scale=$scale', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await _mount(tester, const CreateHomeworkScreen(children: []), language, scale: scale);
        await _tap(tester, find.text(strings.homeworkPublish));
        expect(find.text(strings.homeworkTitleRequired), findsOneWidget);
        expect(find.text(strings.homeworkDescriptionRequired), findsOneWidget);
      });
      testWidgets('$language student homework and grading scale=$scale', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        final writes = <http.Request>[];
        await http.runWithClient(() async {
          await _mount(tester, const TeacherChildDetailsScreen(childId: 7, childName: 'محمود'), language, scale: scale);
          expect(find.text(strings.studentHomeworkTab), findsOneWidget);
          expect(find.text('واجب أصلي 1'), findsOneWidget);
          await _tap(tester, find.widgetWithText(ChoiceChip, '${strings.toGrade} (1)'));
          expect(find.text('واجب أصلي 2'), findsOneWidget);
          expect(find.text('واجب أصلي 1'), findsNothing);
          await _scrollTo(tester, find.text(strings.homeworkGradeAction));
          await _tap(tester, find.text(strings.homeworkGradeAction));
          expect(find.text(strings.homeworkGradeTitle('واجب أصلي 2')), findsOneWidget);
          expect(find.text('إجابة الطالب الأصلية'), findsWidgets);
          await _tap(tester, find.text(strings.homeworkSaveGrade));
          expect(find.text(strings.homeworkGradeRequired), findsOneWidget);
          await tester.enterText(find.byType(TextField).first, '101');
          await _tap(tester, find.text(strings.homeworkSaveGrade));
          expect(find.text(strings.homeworkGradeRange), findsOneWidget);
          await tester.enterText(find.byType(TextField).first, '88');
          await tester.enterText(find.byType(TextField).at(1), 'ملاحظتي الأصلية');
          await _tap(tester, find.text(strings.homeworkSaveGrade));
          expect(find.text(strings.homeworkGradeSaveFailed), findsOneWidget);
          expect(jsonDecode(writes.single.body), {'grade': 88, 'feedback': 'ملاحظتي الأصلية'});
          expect(writes.single.url.path, endsWith('/homeworks/submissions/42/grade'));
          await _tap(tester, find.text(strings.homeworkSaveGrade));
          expect(writes, hasLength(2));
          expect(find.text(strings.homeworkGradeSaved), findsOneWidget);
        }, () => _client(write: (request) async {
          writes.add(request);
          return _response({}, writes.length == 1 ? 500 : 200);
        }));
      });
    }
    testWidgets('$language student lessons preserve authored title and status', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      await http.runWithClient(() async {
        await _mount(tester, const TeacherChildDetailsScreen(childId: 7, childName: 'محمود', initialTab: 1), language, scale: 2);
        expect(find.text(strings.studentLessonsTab), findsOneWidget);
        expect(find.text('درس المعلم الأصلي'), findsOneWidget);
        expect(find.text(strings.completedStatus), findsWidgets);
      }, () => _client());
    });
    testWidgets('$language publishing preserves authored multipart fields and child IDs', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      http.Request? saved;
      await http.runWithClient(() async {
        await _mount(tester, Scaffold(body: Builder(builder: (context) => TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CreateHomeworkScreen(
            children: [{'id': 7, 'name': 'محمود'}], initialChildId: 7,
            initialTitle: 'عنوان أصلي', initialDescription: 'وصف أصلي', initialSubject: 'مادة أصلية',
          ))), child: const Text('Open')))), language);
        await _tap(tester, find.text('Open'));
        await _tap(tester, find.text(strings.homeworkPublish));
        expect(saved?.method, 'POST');
        expect(saved?.url.path, endsWith('/homeworks'));
        expect(utf8.decode(saved!.bodyBytes), contains('عنوان أصلي'));
        expect(utf8.decode(saved!.bodyBytes), contains('وصف أصلي'));
        expect(utf8.decode(saved!.bodyBytes), contains('مادة أصلية'));
        expect(utf8.decode(saved!.bodyBytes), contains('name="assigned_child_ids"\r\n\r\n[7]'));
        expect(find.text('Open'), findsOneWidget);
      }, () => _client(write: (request) async {
        saved = request;
        return _response({'homework': {'id': 5}}, 201);
      }));
    });
    testWidgets('$language empty publish result unlocks retry without losing draft', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      var writes = 0;
      await http.runWithClient(() async {
        await _mount(tester, const CreateHomeworkScreen(
          children: [{'id': 7, 'name': 'محمود'}], initialChildId: 7,
          initialTitle: 'عنوان أصلي', initialDescription: 'وصف أصلي'), language);
        await _tap(tester, find.text(strings.homeworkPublish));
        await _scrollTo(tester, find.text(strings.homeworkPublishFailed));
        expect(find.text(strings.homeworkPublishFailed), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await _tap(tester, find.text(strings.homeworkPublish));
        expect(writes, 2);
      }, () => _client(write: (request) async {
        writes++;
        expect(utf8.decode(request.bodyBytes), contains('عنوان أصلي'));
        return _response({'homework': null}, 201);
      }));
    });
    testWidgets('$language publishing without students explains required selection', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      await _mount(tester, const CreateHomeworkScreen(children: [], initialTitle: 'عنوان', initialDescription: 'وصف'), language);
      await _tap(tester, find.text(strings.homeworkPublish));
      await _scrollTo(tester, find.text(strings.homeworkChooseStudent));
      expect(find.text(strings.homeworkChooseStudent), findsOneWidget);
    });
  }
}
