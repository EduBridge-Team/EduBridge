import 'dart:async';
import 'dart:convert';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/model/enrollment/school_history.dart';
import 'package:edubridge_app/screens/enrollment/school_history_screen.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/enrollment/school_history_repository.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

Map<String, dynamic> record({
  int id = 1,
  int school = 10,
  String status = 'active',
  String start = '2026-09-01',
  String? end,
  int? target,
}) => {
  'id': id, 'child_id': 6, 'school_id': school,
  'school_name': 'School $school', 'section_label': '2026/2027 / Grade 2 / A',
  'status': status, 'started_on': start, 'ended_on': end,
  'transferred_to_enrollment_id': target,
};
Map<String, dynamic> history(List<Map<String, dynamic>> records) =>
    {'child_id': 6, 'enrollments': records};

class FakeHistory implements SchoolHistoryGateway {
  FakeHistory(this.read);
  final Future<SchoolHistory> Function() read;
  @override
  Future<SchoolHistory> load() => read();
}

void main() {
  test('transfer keeps child identity and orders latest school first', () {
    final result = SchoolHistory.fromJson(history([
      record(status: 'transferred', end: '2026-10-01', target: 2),
      record(id: 2, school: 11, start: '2026-10-01'),
    ]), 6);
    expect(result.records.map((r) => r.id), [2, 1]);
    expect(result.records.every((r) => r.childId == 6), isTrue);
    expect(result.records.last.transferredToId, 2);
    expect(() => result.records.clear(), throwsUnsupportedError);
  });

  final invalid = <String, Map<String, dynamic>>{
    'foreign response': {...history([]), 'child_id': 7},
    'foreign record': history([{...record(), 'child_id': 7}]),
    'duplicate ID': history([record(), record()]),
    'multiple active': history([record(), record(id: 2, school: 11)]),
    'impossible date': history([record(start: '2026-02-30')]),
    'active with end': history([record(end: '2026-10-01')]),
    'closed without end': history([record(status: 'closed')]),
    'backward dates': history([record(status: 'closed', end: '2026-08-01')]),
    'unknown status': history([record(status: 'deleted')]),
    'missing end key': history([record()..remove('ended_on')]),
    'missing transfer key': history([record()..remove('transferred_to_enrollment_id')]),
    'missing target': history([record(status: 'transferred', end: '2026-10-01', target: 2)]),
    'same school transfer': history([
      record(status: 'transferred', end: '2026-10-01', target: 2),
      record(id: 2, start: '2026-10-01'),
    ]),
    'target before closure': history([
      record(status: 'transferred', end: '2026-10-01', target: 2),
      record(id: 2, school: 11),
    ]),
    'cycle': history([
      record(status: 'transferred', start: '2026-09-01', end: '2026-09-01', target: 2),
      record(id: 2, school: 11, status: 'transferred',
          start: '2026-09-01', end: '2026-09-01', target: 1),
    ]),
  };
  for (final entry in invalid.entries) {
    test('rejects ${entry.key}', () {
      expect(() => SchoolHistory.fromJson(entry.value, 6), throwsFormatException);
    });
  }

  test('repository reads only child-specific history', () async {
    final repository = SchoolHistoryRepository(
      childId: 6,
      client: EnrollmentApiClient(
        get: (path) async {
          expect(path, '/parent/children/6/school-history');
          return http.Response(jsonEncode(history([record()])), 200);
        },
        post: (_, _) async => throw StateError('Read-only feature'),
      ),
    );
    expect((await repository.load()).records.single.childId, 6);
  });

  for (final entry in {401: EnrollmentFailure.session, 403: EnrollmentFailure.forbidden,
      404: EnrollmentFailure.unavailable, 500: EnrollmentFailure.server}.entries) {
    test('HTTP ${entry.key} is an error, never empty history', () async {
      final repository = SchoolHistoryRepository(childId: 6,
        client: EnrollmentApiClient(get: (_) async => http.Response('{}', entry.key)));
      await expectLater(repository.load(), throwsA(isA<EnrollmentApiException>()
          .having((e) => e.failure, 'failure', entry.value)));
    });
  }

  test('malformed and foreign responses cannot display history', () async {
    for (final data in [{}, history([{...record(), 'child_id': 7}])]) {
      final repository = SchoolHistoryRepository(childId: 6,
        client: EnrollmentApiClient(get: (_) async => http.Response(jsonEncode(data), 200)));
      await expectLater(repository.load(), throwsA(isA<EnrollmentApiException>()
          .having((e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)));
    }
  });

  for (final language in ['ar', 'en']) {
    testWidgets('branded history fits narrow screen with large $language text', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final l10n = await AppLocalizations.delegate.load(Locale(language));
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
          child: child!),
        home: SchoolHistoryScreen(childId: 6, childName: 'طفل',
          gateway: FakeHistory(() async => SchoolHistory.fromJson(history([
            record(status: 'transferred', end: '2026-10-01', target: 2),
            record(id: 2, school: 11, start: '2026-10-01'),
          ]), 6))),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(BrandAppBar), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text(l10n.schoolHistoryTitle), findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('school-history-1')), 200);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unavailable history has no invented records and can reload', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: SchoolHistoryScreen(childId: 6, childName: 'Child',
        gateway: FakeHistory(() async {
          if (++calls == 1) throw const EnrollmentApiException(EnrollmentFailure.unavailable);
          return SchoolHistory.fromJson(history([]), 6);
        })),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Enrollment is not available on the server yet.'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    await tester.tap(find.byTooltip('Reload'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('No school enrollment history.'), findsOneWidget);
  });

  testWidgets('late response after closing screen is ignored', (tester) async {
    final pending = Completer<SchoolHistory>();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SchoolHistoryScreen(childId: 6, childName: 'Child',
        gateway: FakeHistory(() => pending.future)),
    ));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(SchoolHistory.fromJson(history([]), 6));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
