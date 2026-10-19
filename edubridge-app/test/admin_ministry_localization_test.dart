import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/admin/admin_screen.dart';
import 'package:edubridge_app/screens/ministry/ministry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget screen, String language, double scale) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
  home: screen,
);
http.Response _response(Object data, [int status = 200]) => http.Response(jsonEncode(data), status,
  headers: {'content-type': 'application/json; charset=utf-8'});
MockClient _client({List<Map<String, dynamic>> lessons = const [],
    List<Map<String, dynamic>> users = const [],
    Future<http.Response> Function(http.Request)? mutation}) => MockClient((request) async {
  if (request.method != 'GET') return mutation == null ? _response({}, 500) : await mutation(request);
  return _response({'users': users, 'children': [], 'requests': [], 'tickets': [],
    'approvals': [], 'lessons': lessons, 'children_count': 0, 'users_count': users.length});
});
Future<void> _open(WidgetTester tester, bool admin, String language, double scale) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.runAsync(() async {
    await tester.pumpWidget(_host(admin ? const AdminScreen(admin: {'id': 1}) : const MinistryScreen(), language, scale));
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.runAsync(() async {
    await tester.tap(target);
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'userId': 1, 'name': 'ليان'});
  });
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final admin in [true, false]) {
        for (final tab in admin ? [0, 1, 2] : [0, 1, 2, 3]) {
          testWidgets('${admin ? 'admin' : 'ministry'} tab $tab in $language at $scale', (tester) async {
            await http.runWithClient(() async {
              final s = await AppLocalizations.delegate.load(Locale(language));
              await _open(tester, admin, language, scale);
              final labels = admin ? [s.users, s.verificationReview, s.technicalSupport]
                  : [s.overview, s.requests, s.users, s.curricula];
              if (tab > 0) await _tap(tester, find.text(labels[tab]).first);
              expect(find.text(labels[tab]), findsWidgets);
              if (!admin && tab == 2) {
                expect(find.text(s.ministryReadOnlyNotice), findsOneWidget);
                expect(find.byTooltip(s.edit), findsNothing);
                expect(find.byTooltip(s.delete), findsNothing);
              }
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
            }, () => _client());
          });
        }
      }
    }
  }

  for (final role in ['institution', 'ministry']) {
    testWidgets('English admin creates $role with canonical role and original name', (tester) async {
      final payloads = <Map<String, dynamic>>[];
      await http.runWithClient(() async {
        await _open(tester, true, 'en', 1);
        await _tap(tester, find.text('Create institution or ministry account'));
        final dropdown = tester.widget<DropdownButtonFormField<String>>(find.byType(DropdownButtonFormField<String>));
        dropdown.onChanged!(role);
        await tester.pumpAndSettle();
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'مؤسسة الأمل');
        await tester.enterText(fields.at(1), 'invalid');
        await tester.enterText(fields.at(3), 'SecurePass123');
        await tester.enterText(fields.at(4), 'SecurePass123');
        await _tap(tester, find.text('Create account'));
        expect(payloads, isEmpty);
        await tester.enterText(fields.at(1), 'school@example.org');
        await _tap(tester, find.text('Create account'));
        expect(payloads.single['role'], role);
        expect(payloads.single['name'], 'مؤسسة الأمل');
        expect(payloads.single['email'], 'school@example.org');
        expect(payloads.single['password_confirmation'], 'SecurePass123');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => _client(mutation: (request) async {
        expect(request.url.path.endsWith('/users'), isTrue);
        payloads.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
        return _response({'user': {'id': 19}}, 201);
      }));
    });
  }

  testWidgets('English ministry keeps authored lessons and canonical review payload', (tester) async {
    final payloads = <Map<String, dynamic>>[];
    await http.runWithClient(() async {
      await _open(tester, false, 'en', 1);
      await _tap(tester, find.text('Curricula'));
      expect(find.text('دورة حياة الفراشة'), findsOneWidget);
      expect(find.text('محتوى المعلم'), findsOneWidget);
      await _tap(tester, find.text('Reject'));
      expect(find.text('Lesson rejection reason'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'يرجى مراجعة المحتوى');
      await _tap(tester, find.text('Reject lesson'));
      expect(payloads.single, {'status': 'rejected', 'note': 'يرجى مراجعة المحتوى'});
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => _client(lessons: [{
      'id': 51, 'title': 'دورة حياة الفراشة', 'content': 'محتوى المعلم',
    }], mutation: (request) async {
      expect(request.method, 'PUT');
      expect(request.url.path.endsWith('/ministry/lessons/51'), isTrue);
      payloads.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
      return _response({});
    }));
  });
}
