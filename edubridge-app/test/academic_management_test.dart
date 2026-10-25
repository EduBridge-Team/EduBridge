import 'dart:async';
import 'dart:convert';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/model/schools/academic_catalog.dart';
import 'package:edubridge_app/screens/academics/academic_controller.dart';
import 'package:edubridge_app/screens/academics/academic_screen.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/academic_repository.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

Map<String, dynamic> year({int school = 10, String end = '2027-06-30'}) => {
  'id': 1, 'school_id': school, 'name': '2026/2027',
  'starts_on': '2026-09-01', 'ends_on': end, 'is_current': true,
};
Map<String, dynamic> grade() => {'id': 2, 'school_id': 10, 'name': 'Grade 2'};
Map<String, dynamic> section() => {
  'id': 3, 'school_id': 10, 'name': 'A', 'academic_year_id': 1,
  'grade_id': 2, 'capacity': 30,
};
Map<String, dynamic> catalog() => {
  'school': {'id': 10, 'name': 'School'},
  'academic_years': [year()], 'grades': [grade()], 'sections': [section()],
};
http.Response json(Object data, [int status = 200]) =>
    http.Response(jsonEncode(data), status);
Matcher failure(EnrollmentFailure value) => throwsA(isA<EnrollmentApiException>()
    .having((e) => e.failure, 'failure', value));

class FakeAcademic implements AcademicGateway {
  AcademicCatalog data = AcademicCatalog.fromJson(catalog());
  int writes = 0;
  bool failRead = false;
  Completer<void>? pending;
  @override
  Future<AcademicCatalog> load() async {
    if (failRead) throw const EnrollmentApiException(EnrollmentFailure.network);
    return data;
  }
  @override
  Future<void> create(int schoolId, AcademicDraft draft) async {
    writes++;
    if (pending != null) await pending!.future;
  }
}

void main() {
  test('catalog parses immutable scoped relations', () {
    final data = AcademicCatalog.fromJson(catalog());
    expect(data.sections.single.yearId, data.years.single.id);
    expect(data.sections.single.gradeId, data.grades.single.id);
    expect(() => data.years.clear(), throwsUnsupportedError);
  });
  final invalid = <String, Map<String, dynamic>>{
    'foreign year': {...catalog(), 'academic_years': [year(school: 99)]},
    'backwards dates': {...catalog(), 'academic_years': [year(end: '2026-08-01')]},
    'invalid calendar date': {...catalog(), 'academic_years': [year(end: '2027-02-30')]},
    'duplicate years': {...catalog(), 'academic_years': [year(), year()]},
    'missing grade': {...catalog(), 'grades': []},
    'foreign section': {...catalog(), 'sections': [{...section(), 'school_id': 99}]},
    'invalid capacity': {...catalog(), 'sections': [{...section(), 'capacity': 501}]},
    'missing array': catalog()..remove('sections'),
    'nonboolean current': {...catalog(), 'academic_years': [{...year(), 'is_current': 1}]},
  };
  for (final entry in invalid.entries) {
    test('rejects ${entry.key}', () {
      expect(() => AcademicCatalog.fromJson(entry.value), throwsFormatException);
    });
  }
  test('repository resolves authenticated school before its academic catalog', () async {
    final paths = <String>[];
    final repo = AcademicRepository(client: EnrollmentApiClient(get: (path) async {
      paths.add(path);
      return json(path == '/school/context'
          ? {'school': {'id': 10, 'name': 'School', 'organization_id': null}} : catalog());
    }));
    expect((await repo.load()).school.id, 10);
    expect(paths, ['/school/context', '/school/academic']);
  });
  test('foreign catalog cannot pass authenticated school validation', () async {
    final repo = AcademicRepository(client: EnrollmentApiClient(get: (path) async =>
        json(path == '/school/context'
          ? {'school': {'id': 99, 'name': 'Other', 'organization_id': null}} : catalog())));
    await expectLater(repo.load(), failure(EnrollmentFailure.invalidResponse));
  });

  final drafts = [
    AcademicDraft(kind: AcademicKind.year, name: '2026/2027',
      start: DateTime(2026, 9, 1), end: DateTime(2027, 6, 30), current: true),
    const AcademicDraft(kind: AcademicKind.grade, name: 'Grade 2'),
    const AcademicDraft(kind: AcademicKind.section, name: 'A',
      yearId: 1, gradeId: 2, capacity: 30),
  ];
  for (final draft in drafts) {
    test('create ${draft.kind.name} asserts school and saved fields', () async {
      final item = switch (draft.kind) {
        AcademicKind.year => year(),
        AcademicKind.grade => grade(),
        AcademicKind.section => section(),
      };
      var calls = 0;
      final repo = AcademicRepository(client: EnrollmentApiClient(post: (path, body) async {
        calls++;
        expect(path.startsWith('/school/academic/'), isTrue);
        expect(body, {...draft.toJson(), 'expected_school_id': 10});
        return json({'school_id': 10, 'item': item}, 201);
      }));
      await repo.create(10, draft);
      expect(calls, 1);
    });
    test('mismatched ${draft.kind.name} receipt cannot confirm save', () async {
      final item = switch (draft.kind) {
        AcademicKind.year => {...year(), 'ends_on': '2027-07-01'},
        AcademicKind.grade => {...grade(), 'name': 'Old grade'},
        AcademicKind.section => {...section(), 'capacity': 31},
      };
      final repo = AcademicRepository(client: EnrollmentApiClient(post: (path, body) async =>
          json({'school_id': 10, 'item': item}, 201)));
      await expectLater(repo.create(10, draft), failure(EnrollmentFailure.invalidResponse));
    });
  }
  test('invalid drafts never send requests', () async {
    var writes = 0;
    final repo = AcademicRepository(client: EnrollmentApiClient(post: (path, body) async {
      writes++;
      return json({}, 201);
    }));
    await expectLater(repo.create(10, const AcademicDraft(
      kind: AcademicKind.section, name: 'A', yearId: 1, gradeId: 2, capacity: 0)),
      failure(EnrollmentFailure.validation));
    expect(writes, 0);
  });
  test('controller rejects foreign year and serializes writes', () async {
    final gateway = FakeAcademic()..pending = Completer<void>();
    final controller = AcademicController(gateway);
    await controller.reload();
    expect(await controller.create(const AcademicDraft(kind: AcademicKind.section,
      name: 'A', yearId: 99, gradeId: 2, capacity: 30)), isFalse);
    final first = controller.create(drafts[1]);
    await controller.create(drafts[1]);
    expect(gateway.writes, 1);
    gateway.pending!.complete();
    expect(await first, isTrue);
    controller.dispose();
  });
  test('confirmed save plus refresh failure never replays mutation', () async {
    final gateway = FakeAcademic();
    final controller = AcademicController(gateway);
    await controller.reload();
    gateway.failRead = true;
    expect(await controller.create(drafts[1]), isTrue);
    expect(controller.saved, isTrue);
    expect(controller.snapshot, isNull);
    expect(controller.error, EnrollmentFailure.network);
    expect(await controller.create(drafts[1]), isFalse);
    expect(gateway.writes, 1);
    controller.dispose();
  });

  for (final language in ['ar', 'en']) {
    testWidgets('catalog and grade form fit narrow large $language text', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gateway = FakeAcademic();
      final l10n = await AppLocalizations.delegate.load(Locale(language));
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language), supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
          child: child!),
        home: AcademicScreen(gateway: gateway),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(BrandAppBar), findsOneWidget);
      final add = find.byKey(const ValueKey('academic-add-grade'));
      await tester.scrollUntilVisible(add, 150,
        scrollable: find.descendant(of: find.byType(ListView),
          matching: find.byType(Scrollable)).first);
      await Scrollable.ensureVisible(tester.element(add), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('academic-save')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.academicRequired), findsOneWidget);
      expect(gateway.writes, 0);
      await tester.enterText(find.byKey(const ValueKey('academic-name')), 'Grade 3');
      await tester.tap(find.byKey(const ValueKey('academic-save')));
      await tester.pumpAndSettle();
      expect(gateway.writes, 1);
      expect(find.text(l10n.academicTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
