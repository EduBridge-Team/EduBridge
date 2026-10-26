import 'dart:async';

import 'package:edubridge_app/model/schools/academic_catalog.dart';
import 'package:edubridge_app/screens/institution_academics/institution_academic_controller.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'institution_academic_write_fixture.dart';

AcademicDraft institutionDraft(AcademicKind kind) => AcademicDraft(
  kind: kind,
  name: ' سجل جديد ',
  start: DateTime(2027, 9, 1),
  end: DateTime(2028, 6, 30),
  yearId: 10,
  gradeId: 20,
  capacity: 30,
  current: true,
);
void main() {
  for (final kind in AcademicKind.values) {
    test(
      'actual ${kind.name} write sends exact fields and verifies keyed receipt',
      () async {
        final fixture = InstitutionAcademicWriteFixture();
        final repository = fixture.repository;
        final before = await repository.load();
        final draft = institutionDraft(kind);
        await repository.create(before, draft);
        expect(fixture.writes.single.body, draft.toJson());
        expect(
          fixture.writes.single.path,
          '/institutions/demo-institution/schools/5/academic/${switch (kind) {
            AcademicKind.year => 'years',
            AcademicKind.grade => 'grades',
            AcademicKind.section => 'sections',
          }}',
        );
        expect(fixture.reads.length, 4);
      },
    );
    test('mismatched ${kind.name} receipt never confirms success', () async {
      final fixture = InstitutionAcademicWriteFixture()..tamper = true;
      final repository = fixture.repository;
      final before = await repository.load();
      await expectLater(
        repository.create(before, institutionDraft(kind)),
        throwsA(
          isA<EnrollmentApiException>().having(
            (e) => e.failure,
            'failure',
            EnrollmentFailure.invalidResponse,
          ),
        ),
      );
    });
  }
  test('changed institution and removed parents prevent POST', () async {
    final fixture = InstitutionAcademicWriteFixture();
    final repository = fixture.repository;
    final before = await repository.load();
    fixture.slug = 'other-institution';
    await expectLater(
      repository.create(before, institutionDraft(AcademicKind.grade)),
      throwsA(isA<EnrollmentApiException>()),
    );
    expect(fixture.writes, isEmpty);
    fixture.slug = 'demo-institution';
    fixture.data['sections'] = [];
    fixture.data['grades'] = [];
    await expectLater(
      repository.create(before, institutionDraft(AcademicKind.section)),
      throwsA(
        isA<EnrollmentApiException>().having(
          (e) => e.failure,
          'failure',
          EnrollmentFailure.conflict,
        ),
      ),
    );
    expect(fixture.writes, isEmpty);
  });
  test('controller serializes writes and keeps confirmed save after failed refresh', () async {
    final fixture = InstitutionAcademicWriteFixture()..failRefresh = true;
    final controller = InstitutionAcademicController(
      fixture.repository,
      organizationSlug: 'demo-institution',
      schoolId: 5,
    );
    addTearDown(controller.dispose);
    await controller.reload();
    fixture.pending = Completer<void>();
    final first = controller.create(institutionDraft(AcademicKind.grade));
    expect(controller.busy, isTrue);
    expect(
      await controller.create(institutionDraft(AcademicKind.grade)),
      isFalse,
    );
    fixture.pending!.complete();
    expect(await first, isTrue);
    expect(controller.saved, isTrue);
    expect(controller.error, EnrollmentFailure.server);
    expect(controller.snapshot, isNull);
    await controller.reload();
    expect(fixture.writes, hasLength(1));
  });
  for (final status in [401, 403, 409, 422, 503]) {
    test('failed write $status cannot become a confirmed save', () async {
      final fixture = InstitutionAcademicWriteFixture()..status = status;
      final controller = InstitutionAcademicController(
        fixture.repository,
        organizationSlug: 'demo-institution',
        schoolId: 5,
      );
      addTearDown(controller.dispose);
      await controller.reload();
      expect(
        await controller.create(institutionDraft(AcademicKind.grade)),
        isFalse,
      );
      expect(controller.saved, isFalse);
      expect(fixture.writes, hasLength(1));
    });
  }
  test('disposed write state cannot confirm a late save or block back indefinitely', () async {
    final fixture = InstitutionAcademicWriteFixture()
      ..pending = Completer<void>();
    final controller = InstitutionAcademicController(
      fixture.repository,
      organizationSlug: 'demo-institution',
      schoolId: 5,
    );
    await controller.reload();
    final saving = controller.create(institutionDraft(AcademicKind.grade));
    controller.dispose();
    fixture.pending!.complete();
    expect(await saving, isFalse);
    expect(controller.busy, isFalse);
    expect(controller.canWrite, isFalse);
  });
}
