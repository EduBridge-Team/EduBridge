import 'dart:async';
import 'dart:convert';

import 'package:edubridge_app/model/schools/curriculum_catalog.dart';
import 'package:edubridge_app/model/schools/curriculum_draft.dart';
import 'package:edubridge_app/screens/curriculum/curriculum_controller.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/curriculum_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'curriculum_http_fixture.dart';

void main() {
  test('catalog is scoped, immutable, and retains authored labels', () {
    final data = CurriculumCatalog.fromJson(curriculumPayload());
    expect(data.terms.single.name, curriculumTerm()['name']);
    expect(data.subjects.single.active, isFalse);
    expect(() => data.terms.clear(), throwsUnsupportedError);
    expect(() => data.years.clear(), throwsUnsupportedError);
    expect(() => data.subjects.clear(), throwsUnsupportedError);
  });
  final invalid = <String, Map<String, dynamic>>{
    'foreign year': {
      ...curriculumPayload(),
      'academic_years': [
        {...curriculumYear(), 'school_id': 99},
      ],
    },
    'missing year': {...curriculumPayload(), 'academic_years': []},
    'duplicate year': {
      ...curriculumPayload(),
      'academic_years': [curriculumYear(), curriculumYear()],
    },
    'duplicate term': {
      ...curriculumPayload(),
      'academic_terms': [curriculumTerm(), curriculumTerm()],
    },
    'duplicate position': {
      ...curriculumPayload(),
      'academic_terms': [
        curriculumTerm(),
        {...curriculumTerm(), 'id': 5},
      ],
    },
    'foreign term': {
      ...curriculumPayload(),
      'academic_terms': [
        {...curriculumTerm(), 'school_id': 99},
      ],
    },
    'term outside year': {
      ...curriculumPayload(),
      'academic_terms': [
        {...curriculumTerm(), 'ends_on': '2028-01-01'},
      ],
    },
    'reversed term': {
      ...curriculumPayload(),
      'academic_terms': [
        {...curriculumTerm(), 'ends_on': '2026-08-01'},
      ],
    },
    'invalid date': {
      ...curriculumPayload(),
      'academic_terms': [
        {...curriculumTerm(), 'ends_on': '2027-02-30'},
      ],
    },
    'invalid position': {
      ...curriculumPayload(),
      'academic_terms': [
        {...curriculumTerm(), 'position': 21},
      ],
    },
    'foreign subject': {
      ...curriculumPayload(),
      'subjects': [
        {...curriculumSubject(), 'school_id': 99},
      ],
    },
    'duplicate subject': {
      ...curriculumPayload(),
      'subjects': [curriculumSubject(), curriculumSubject()],
    },
    'invalid boolean': {
      ...curriculumPayload(),
      'subjects': [
        {...curriculumSubject(), 'is_active': 1},
      ],
    },
    'missing code': {
      ...curriculumPayload(),
      'subjects': [curriculumSubject()..remove('code')],
    },
    'missing array': curriculumPayload()..remove('academic_terms'),
  };
  for (final entry in invalid.entries) {
    test(
      'rejects ${entry.key}',
      () => expect(
        () => CurriculumCatalog.fromJson(entry.value),
        throwsFormatException,
      ),
    );
  }
  test('term validates year bounds, scope and unused order', () {
    final data = CurriculumCatalog.fromJson(curriculumPayload());
    expect(termDraft().validFor(data), isTrue);
    expect(termDraft(position: 1).validFor(data), isFalse);
    expect(termDraft(year: 99).validFor(data), isFalse);
    expect(
      CurriculumDraft(
        kind: CurriculumKind.term,
        name: 'Term',
        yearId: 1,
        position: 2,
        start: DateTime(2026, 8, 1),
        end: DateTime(2027, 6, 30),
      ).validFor(data),
      isFalse,
    );
    expect(
      CurriculumDraft(
        kind: CurriculumKind.term,
        name: 'Term',
        yearId: 1,
        position: 2,
        start: DateTime(2027, 1, 1),
        end: DateTime(2027, 1, 1, 23),
      ).valid,
      isFalse,
    );
    expect(
      const CurriculumDraft(
        kind: CurriculumKind.subject,
        name: 'Science',
        code: ' ',
      ).toJson()['code'],
      isNull,
    );
  });
  test(
    'repository rejects catalog from another authenticated school',
    () async {
      final fixture = CurriculumHttpFixture()..contextSchool = 99;
      await expectLater(
        fixture.repository.load(),
        throwsA(
          isA<EnrollmentApiException>().having(
            (e) => e.failure,
            'failure',
            EnrollmentFailure.invalidResponse,
          ),
        ),
      );
    },
  );
  for (final draft in [termDraft(), subjectDraft]) {
    test('${draft.kind.name} create uses exact contract and confirms receipt', () async {
      final fixture = CurriculumHttpFixture();
      await fixture.repository.create(10, draft);
      expect(fixture.writes.single, {
        'path':
            '/school/academic/${draft.kind == CurriculumKind.term ? 'terms' : 'subjects'}',
        ...draft.toJson(),
        'expected_school_id': 10,
      });
    });
    test(
      '${draft.kind.name} mismatched receipt clears actions without replay',
      () async {
        final fixture = CurriculumHttpFixture()..badReceipt = true;
        final controller = CurriculumController(fixture.repository);
        addTearDown(controller.dispose);
        await controller.reload();
        expect(await controller.create(draft), isFalse);
        expect(controller.error, EnrollmentFailure.invalidResponse);
        expect(controller.snapshot, isNull);
        expect(await controller.create(draft), isFalse);
        expect(fixture.writes.length, 1);
      },
    );
  }
  test('foreign receipt is never accepted', () async {
    final repo = CurriculumRepository(
      client: EnrollmentApiClient(
        post: (path, body) async => http.Response(
          jsonEncode({'school_id': 99, 'item': curriculumSubject()}),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    await expectLater(
      repo.create(10, subjectDraft),
      throwsA(isA<EnrollmentApiException>()),
    );
  });
  test('concurrent create is serialized and successful save survives failed refresh', () async {
    final fixture = CurriculumHttpFixture()
      ..pending = Completer<void>()
      ..failAfterWrite = true;
    final controller = CurriculumController(fixture.repository);
    addTearDown(controller.dispose);
    await controller.reload();
    expect(await controller.create(termDraft(position: 1)), isFalse);
    expect(fixture.writes, isEmpty);
    final saved = controller.create(subjectDraft);
    await controller.create(subjectDraft);
    expect(fixture.writes.length, 1);
    fixture.pending!.complete();
    expect(await saved, isTrue);
    expect(controller.saved, isTrue);
    expect(controller.snapshot, isNull);
    expect(controller.error, EnrollmentFailure.unavailable);
    expect(await controller.create(subjectDraft), isFalse);
    expect(fixture.writes.length, 1);
  });
  test('invalid drafts never reach the HTTP client', () async {
    final fixture = CurriculumHttpFixture();
    await expectLater(
      fixture.repository.create(
        10,
        const CurriculumDraft(kind: CurriculumKind.subject, name: ' '),
      ),
      throwsA(isA<EnrollmentApiException>()),
    );
    expect(fixture.writes, isEmpty);
  });
}
