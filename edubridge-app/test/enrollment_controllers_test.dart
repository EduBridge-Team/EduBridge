import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/enrollment/enrollment_models.dart';
import 'package:edubridge_app/screens/enrollment/enrollment_controllers.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';

import 'enrollment_fakes.dart';

void main() {
  test('school decision serializes and blocks repeat approval', () async {
    final gateway = FakeSchoolEnrollment()..pendingWrite = Completer<void>();
    final controller = SchoolEnrollmentController(gateway);
    addTearDown(controller.dispose);
    await controller.reload();
    final request = controller.snapshot!.requests.single;
    final first = controller.decide(
      request,
      const EnrollmentDecision(approve: true, sectionId: 20),
    );
    await controller.decide(
      request,
      const EnrollmentDecision(approve: true, sectionId: 20),
    );
    expect(gateway.writes, 1);
    gateway.pendingWrite!.complete();
    await first;
    expect(
      controller.snapshot!.requests.single.status,
      EnrollmentStatus.approved,
    );
  });
  test('school cannot submit a foreign section', () async {
    final gateway = FakeSchoolEnrollment();
    final controller = SchoolEnrollmentController(gateway);
    addTearDown(controller.dispose);
    await controller.reload();
    await controller.decide(
      controller.snapshot!.requests.single,
      const EnrollmentDecision(approve: true, sectionId: 99),
    );
    expect(gateway.writes, 0);
  });
  test(
    'confirmed decision and failed refresh do not repeat decision',
    () async {
      final gateway = FakeSchoolEnrollment()..failRefresh = true;
      final controller = SchoolEnrollmentController(gateway);
      addTearDown(controller.dispose);
      await controller.reload();
      await controller.decide(
        controller.snapshot!.requests.single,
        const EnrollmentDecision(approve: true, sectionId: 20),
      );
      expect(controller.saved, isTrue);
      expect(controller.snapshot, isNull);
      expect(controller.canWrite, isFalse);
      gateway.failRefresh = false;
      await controller.reload();
      expect(gateway.writes, 1);
    },
  );
  test('late school read is ignored after disposal', () async {
    final gateway = FakeSchoolEnrollment()
      ..pendingRead = Completer<SchoolEnrollmentInbox>();
    final controller = SchoolEnrollmentController(gateway);
    final load = controller.reload();
    controller.dispose();
    gateway.pendingRead!.complete(
      SchoolEnrollmentInbox(
        identity: const SchoolPortalIdentity(
          school: enrollmentSchool,
          organizationId: null,
        ),
        requests: [],
        sections: [],
      ),
    );
    await load;
    expect(controller.snapshot, isNull);
  });
  test('older parent school search cannot replace newer results', () async {
    final gateway = FakeParentEnrollment();
    gateway.pendingSearch['old'] = Completer<List<EnrollmentSchool>>();
    final controller = ParentEnrollmentController(gateway);
    addTearDown(controller.dispose);
    await controller.reload();
    final old = controller.search('old');
    await controller.search('new');
    gateway.pendingSearch['old']!.complete([
      const EnrollmentSchool(id: 99, name: 'Old'),
    ]);
    await old;
    expect(controller.schools.single.id, 10);
  });
  test('clearing search invalidates pending results', () async {
    final gateway = FakeParentEnrollment();
    gateway.pendingSearch['old'] = Completer<List<EnrollmentSchool>>();
    final controller = ParentEnrollmentController(gateway);
    addTearDown(controller.dispose);
    await controller.reload();
    final old = controller.search('old');
    controller.clearSearch();
    gateway.pendingSearch['old']!.complete([enrollmentSchool]);
    await old;
    expect(controller.schools, isEmpty);
    expect(controller.searching, isFalse);
  });
  test(
    'parent pending request blocks another submission and permits cancel',
    () async {
      final gateway = FakeParentEnrollment();
      final controller = ParentEnrollmentController(gateway);
      addTearDown(controller.dispose);
      await controller.reload();
      await controller.search('School');
      await controller.submit(controller.schools.single);
      await controller.submit(controller.schools.single);
      expect(gateway.writes, 1);
      await controller.cancel(controller.snapshot!.requests.single);
      expect(gateway.writes, 2);
      expect(controller.snapshot!.canRequest, isTrue);
    },
  );
  test('ambiguous parent write clears actions until reload', () async {
    final gateway = FakeParentEnrollment()
      ..writeFailure = EnrollmentFailure.uncertain;
    final controller = ParentEnrollmentController(gateway);
    addTearDown(controller.dispose);
    await controller.reload();
    await controller.search('School');
    await controller.submit(controller.schools.single);
    expect(controller.snapshot, isNull);
    expect(controller.saved, isFalse);
    await controller.submit(controller.schools.single);
    expect(gateway.writes, 1);
  });
  for (final failure in [
    EnrollmentFailure.session,
    EnrollmentFailure.forbidden,
    EnrollmentFailure.unavailable,
  ]) {
    test(
      'school $failure removes stale decisions until a successful reload',
      () async {
        final gateway = FakeSchoolEnrollment()..writeFailure = failure;
        final controller = SchoolEnrollmentController(gateway);
        addTearDown(controller.dispose);
        await controller.reload();
        final request = controller.snapshot!.requests.single;
        const decision = EnrollmentDecision(
          approve: false,
          reason: 'No capacity',
        );
        await controller.decide(request, decision);
        expect(controller.error, failure);
        expect(controller.snapshot, isNull);
        expect(controller.canWrite, isFalse);
        await controller.decide(request, decision);
        expect(gateway.writes, 1);
        gateway.writeFailure = null;
        await controller.reload();
        expect(controller.canWrite, isTrue);
      },
    );
    test(
      'parent $failure blocks another submission until a successful reload',
      () async {
        final gateway = FakeParentEnrollment()..writeFailure = failure;
        final controller = ParentEnrollmentController(gateway);
        addTearDown(controller.dispose);
        await controller.reload();
        await controller.search('School');
        final school = controller.schools.single;
        await controller.submit(school);
        expect(controller.error, failure);
        expect(controller.snapshot, isNull);
        expect(controller.canWrite, isFalse);
        await controller.submit(school);
        expect(gateway.writes, 1);
        gateway.writeFailure = null;
        await controller.reload();
        expect(controller.canWrite, isTrue);
      },
    );
  }
  test(
    'validation rejection retains editable context without claiming a save',
    () async {
      final gateway = FakeParentEnrollment()
        ..writeFailure = EnrollmentFailure.validation;
      final controller = ParentEnrollmentController(gateway);
      addTearDown(controller.dispose);
      await controller.reload();
      await controller.search('School');
      await controller.submit(controller.schools.single);
      expect(controller.saved, isFalse);
      expect(controller.canWrite, isTrue);
      expect(controller.snapshot!.canRequest, isTrue);
      gateway.writeFailure = null;
      await controller.submit(controller.schools.single);
      expect(gateway.writes, 2);
      expect(controller.saved, isTrue);
    },
  );
}
