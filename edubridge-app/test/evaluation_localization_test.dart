import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/evaluation/evaluation_sheet.dart';
import 'package:edubridge_app/screens/plan_evaluation_screen.dart';
import 'package:edubridge_app/screens/specialist/specialist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget screen, String language, {double scale = 1}) => MaterialApp(
  locale: Locale(language), supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.linear(scale)), child: child!), home: screen);
http.Response _response(Object data, [int status = 200]) => http.Response(jsonEncode(data), status,
  headers: {'content-type': 'application/json; charset=utf-8'});
MockClient _client({bool verified = true, bool dashboard = false,
  Future<http.Response> Function(http.Request)? post}) => MockClient((request) async {
  if (request.method != 'GET') {
    return post == null ? _response({}, 500) : await post(request);
  }
  if (request.url.path.endsWith('/me/verification')) {
    return _response({'verification': {
      'verification_status': verified ? 'approved' : 'none',
    }});
  }
  if (request.url.path.endsWith('/me')) {
    return _response({'user': {'id': 2, 'specialty': 'educational'}});
  }
  if (request.url.path.endsWith('/users')) {
    return _response({'users': [
      {'id': 3, 'name': 'مختص الدعم', 'specialty': 'learning_support'},
      {'id': 4, 'name': 'مختص تعليمي', 'specialty': 'educational'},
    ]});
  }
  return _response({'children': dashboard ? [
    {'id': 8, 'name': 'محمود', 'age': 9, 'status': 'active', 'specialist_ids': [2]},
  ] : [], 'lessons': [], 'disability_types': [], 'progress': []});
});
Future<void> _narrow(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}
Future<void> _mount(WidgetTester tester, Widget screen, String language, {double scale = 1}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(_host(screen, language, scale: scale));
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(finder.hitTestable());
    await tester.pump();
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
Future<void> _evaluationRoute(WidgetTester tester, String language,
    ValueChanged<Map> saved) => _mount(tester, Scaffold(body: Builder(builder: (context) => TextButton(
  onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true,
    builder: (_) => EvaluationSheet(child: {'id': 8, 'name': 'محمود'},
      teachers: const [{'id': 9, 'name': 'معلم', 'email': 'teacher@example.org'}], onSaved: saved)),
  child: const Text('Open')))), language);
Future<void> _fillEvaluation(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.enterText(find.byType(TextFormField).at(i), 'نص المختص الأصلي $i');
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'userId': 2, 'name': 'ليان', 'role': 'specialist'});
  });
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final ministry in [false, true]) {
        testWidgets('$language evaluation ministry=$ministry scale=$scale localizes required fields', (tester) async {
          await _narrow(tester);
          final s = await AppLocalizations.delegate.load(Locale(language));
          await _mount(tester, Scaffold(body: EvaluationSheet(
            child: const {'id': 8, 'name': 'محمود'}, teachers: const [], onSaved: (_) {})), language, scale: scale);
          if (ministry) {
            await _tap(tester, find.byType(Switch));
            expect(find.text(s.rejectionReturnsPlan), findsOneWidget);
          }
          await _tap(tester, find.text(ministry ? s.sendToMinistry : s.sendToTeachers));
          expect(find.text(s.fieldRequired), findsNWidgets(6));
          expect(find.text(s.evaluationForChild('محمود')), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
      testWidgets('$language plan evaluation scale=$scale fits translated choices', (tester) async {
        await _narrow(tester);
        final s = await AppLocalizations.delegate.load(Locale(language));
        await _mount(tester, const PlanEvaluationScreen(childId: 8, childName: 'محمود', planId: 5), language, scale: scale);
        expect(find.text(s.planNeedsChanges), findsOneWidget);
        await tester.scrollUntilVisible(find.text(s.saveEvaluation), 150,
          scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        expect(find.text(s.planEvaluationForChild('محمود')), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      });
      testWidgets('$language specialist suggestion scale=$scale preserves IDs and authored reason', (tester) async {
        await _narrow(tester);
        final s = await AppLocalizations.delegate.load(Locale(language));
        final payloads = <Map<String, dynamic>>[];
        await http.runWithClient(() async {
          await _mount(tester, Scaffold(body: Builder(builder: (context) => TextButton(
            onPressed: () => showChildSpecialistSuggestion(context, child: {'id': 8, 'name': 'محمود'}),
            child: const Text('Open')))), language, scale: scale);
          await _tap(tester, find.text('Open'));
          await _tap(tester, find.widgetWithText(FilledButton, s.sendRecommendation));
          expect(find.text(s.chooseSpecialist), findsOneWidget);
          tester.widget<RadioGroup<int>>(find.byType(RadioGroup<int>)).onChanged(3);
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const ValueKey('s22_reason')), 'أوصي بالمتابعة مع هذا المختص');
          await _tap(tester, find.widgetWithText(FilledButton, s.sendRecommendation));
          expect(payloads.single, {'specialist_id': 3, 'specialty': 'learning_support',
            'reason': 'أوصي بالمتابعة مع هذا المختص'});
          expect(find.byKey(const ValueKey('s22_reason')), findsNothing);
          await tester.pumpWidget(const SizedBox.shrink());
        }, () => _client(post: (request) async {
          expect(request.url.path.endsWith('/children/8/specialist-suggestions'), isTrue);
          payloads.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
          return _response({}, 201);
        }));
      });
    }
  }

  for (final teacher in [false, true]) {
    testWidgets('English evaluation preserves payload and waits for success acknowledgement teacher=$teacher', (tester) async {
      final posts = <Map<String, dynamic>>[];
      Map? saved;
      await http.runWithClient(() async {
        await _evaluationRoute(tester, 'en', (value) => saved = value);
        await _tap(tester, find.text('Open'));
        await _fillEvaluation(tester);
        tester.widget<DropdownButtonFormField<String>>(find.byType(DropdownButtonFormField<String>)).onChanged!('follow_up');
        if (teacher) {
          tester.widget<DropdownButtonFormField<int?>>(find.byType(DropdownButtonFormField<int?>)).onChanged!(9);
        }
        await tester.pumpAndSettle();
        await _tap(tester, find.text('Send to teachers'));
        expect(posts.first['evaluation_type'], 'follow_up');
        expect(posts.first['cognitive_assessment'], 'نص المختص الأصلي 0');
        expect(posts.first['educational_plan'], 'نص المختص الأصلي 5');
        expect(posts.first['teaching_methods'], ['عام']);
        expect(posts.first['assigned_teacher_id'], teacher ? 9 : null);
        expect(saved!['status'], teacher ? 'assigned' : 'evaluated');
        expect(find.text('Evaluation completed'), findsOneWidget);
        await _tap(tester, find.text('OK'));
        expect(find.byType(EvaluationSheet), findsNothing);
        expect(find.text('Open'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => _client(post: (request) async {
        final body = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        if (request.url.path.endsWith('/notifications/send')) {
          expect(body['user_id'], 9);
          expect(body['type'], 'evaluation_created');
          return _response({});
        }
        expect(request.url.path.endsWith('/evaluations/child/8'), isTrue);
        posts.add(body);
        return _response({'evaluation': {'id': 77}}, 201);
      }));
    });
  }

  testWidgets('ministry submission preserves evaluation content and approval routing', (tester) async {
    final paths = <String>[];
    Map<String, dynamic>? approval;
    await http.runWithClient(() async {
      await _evaluationRoute(tester, 'en', (_) {});
      await _tap(tester, find.text('Open'));
      await _fillEvaluation(tester);
      await _tap(tester, find.byType(Switch));
      await _tap(tester, find.text('Send to ministry'));
      expect(paths, ['/evaluations/child/8', '/ministry/approvals']);
      expect(approval!['child_id'], 8);
      expect(approval!['evaluation_id'], 77);
      expect(approval!['educational_plan'], 'نص المختص الأصلي 5');
      expect(approval!['teaching_methods'], ['عام']);
      expect(find.text('Sent to the ministry'), findsOneWidget);
      await _tap(tester, find.text('OK'));
      expect(find.byType(EvaluationSheet), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => _client(post: (request) async {
      final path = request.url.path;
      if (path.endsWith('/ministry/approvals')) {
        paths.add('/ministry/approvals');
        approval = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        return _response({'approval': {'id': 88, 'child_id': 8, 'evaluation_id': 77, 'status': 'pending'}}, 201);
      }
      paths.add('/evaluations/child/8');
      return _response({'evaluation': {'id': 77}}, 201);
    }));
  });

  testWidgets('failed child evaluation preserves draft and does not call onSaved', (tester) async {
    var saved = false;
    await http.runWithClient(() async {
      await _evaluationRoute(tester, 'en', (_) => saved = true);
      await _tap(tester, find.text('Open'));
      await _fillEvaluation(tester);
      await _tap(tester, find.text('Send to teachers'));
      expect(saved, isFalse);
      expect(find.byType(EvaluationSheet), findsOneWidget);
      expect(tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text, 'نص المختص الأصلي 0');
      expect(find.byType(AlertDialog), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => _client(post: (_) async => _response({'error': 'فشل من الخادم'}, 500)));
  });

  testWidgets('failed plan save can retry without losing notes or boolean values', (tester) async {
    final payloads = <Map<String, dynamic>>[];
    await http.runWithClient(() async {
      await _mount(tester, Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) =>
          const PlanEvaluationScreen(childId: 8, childName: 'محمود', planId: 5))),
        child: const Text('Open')))), 'en');
      await _tap(tester, find.text('Open'));
      tester.widget<RadioGroup<bool>>(find.byType(RadioGroup<bool>)).onChanged(false);
      await tester.enterText(find.byType(TextField).at(0), 'ملاحظات أصلية');
      await tester.enterText(find.byType(TextField).at(1), 'تغيير أول\nتغيير ثان');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Save evaluation').hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
      await _tap(tester, find.text('Save evaluation'));
      expect(find.text('Could not save the evaluation'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNotNull);
      await _tap(tester, find.text('Save evaluation'));
      expect(payloads.length, 2);
      expect(payloads.last, {'child_id': 8, 'is_plan_appropriate': false,
        'notes_for_teacher': 'ملاحظات أصلية', 'recommended_changes': ['تغيير أول', 'تغيير ثان']});
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => _client(post: (request) async {
      expect(request.url.path.endsWith('/plans/5/evaluate'), isTrue);
      payloads.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
      return _response({}, payloads.length == 1 ? 500 : 201);
    }));
  });

  testWidgets('unverified specialist cannot open the recommendation form', (tester) async {
    await http.runWithClient(() async {
      await _mount(tester, Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () => showChildSpecialistSuggestion(context, child: {'id': 8, 'name': 'محمود'}),
        child: const Text('Open')))), 'en');
      await _tap(tester, find.text('Open'));
      expect(find.byKey(const ValueKey('s22_reason')), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => _client(verified: false));
  });

  testWidgets('evaluation validation changes language without replacing authored draft', (tester) async {
    final language = ValueNotifier('ar');
    addTearDown(language.dispose);
    await tester.pumpWidget(ValueListenableBuilder<String>(valueListenable: language,
      builder: (_, locale, __) => _host(Scaffold(body: EvaluationSheet(
        child: const {'id': 8, 'name': 'محمود'}, teachers: const [], onSaved: (_) {})), locale)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'تقييم أصلي');
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    await _tap(tester, find.text(ar.sendToTeachers));
    expect(find.text(ar.fieldRequired), findsNWidgets(5));
    language.value = 'en';
    await tester.pumpAndSettle();
    expect(find.text(en.fieldRequired), findsNWidgets(5));
    expect(find.text(ar.fieldRequired), findsNothing);
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text, 'تقييم أصلي');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('parent recommendation rejects failed HTTP responses and preserves canonical reason on retry', (tester) async {
    final payloads = <Map<String, dynamic>>[];
    await http.runWithClient(() async {
      await _mount(tester, const SpecialistDashboardScreen(), 'en');
      final s = await AppLocalizations.delegate.load(const Locale('en'));
      final scrollable = find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(find.text(s.quickActions).hitTestable(), 200, scrollable: scrollable);
      await _tap(tester, find.text(s.quickActions));
      await tester.scrollUntilVisible(find.text(s.suggestSupport).hitTestable(), 200, scrollable: scrollable);
      await _tap(tester, find.text(s.suggestSupport));
      await _tap(tester, find.byKey(const ValueKey('s28-parent')));
      await _tap(tester, find.byKey(const ValueKey('s28-next')));
      await _tap(tester, find.byKey(const ValueKey('s23_send')));
      expect(find.text(s.chooseRecommendationReason), findsOneWidget);
      tester.widget<DropdownButtonFormField<String>>(find.byKey(const ValueKey('s23_reason'))).onChanged!('صعوبة في فهم الدروس');
      await tester.enterText(find.byKey(const ValueKey('s23_description')), 'وصف أصلي لأسباب هذه التوصية');
      await _tap(tester, find.byKey(const ValueKey('s23_urgency_high')));
      await _tap(tester, find.byKey(const ValueKey('s23_send')));
      expect(find.text(s.recommendationSendFailed), findsOneWidget);
      expect(find.byKey(const ValueKey('s23_description')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('s23_send')));
      expect(payloads.length, 2);
      expect(payloads.last, {'child_id': 8, 'reason': 'صعوبة في فهم الدروس',
        'description': 'وصف أصلي لأسباب هذه التوصية', 'urgency': 'high'});
      expect(find.byKey(const ValueKey('s23_description')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => _client(dashboard: true, post: (request) async {
      expect(request.url.path.endsWith('/learning-support/recommendations'), isTrue);
      payloads.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
      return _response({}, payloads.length == 1 ? 422 : 201);
    }));
  });
}
