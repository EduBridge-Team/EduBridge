import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/schools/school_director.dart';
import 'package:edubridge_app/screens/school_directors/school_directors_controller.dart';
import 'package:edubridge_app/services/schools/director_api_client.dart';

import 'school_directors_fakes.dart';

void main() {
  test('late school A read cannot replace school B', () async {
    final gateway = FakeSchoolDirectors();
    gateway.pendingReads[10] = Completer<DirectorDirectory>();
    final controller = SchoolDirectorsController(gateway);
    addTearDown(controller.dispose);
    await controller.initialize();
    final old = controller.select(directorSchoolA);
    await controller.select(directorSchoolB);
    gateway.pendingReads[10]!.complete(directorDirectory());
    await old;
    expect(controller.school, directorSchoolB);
    expect(controller.directory!.directors, isEmpty);
    expect(controller.loading, isFalse);
  });

  test('writes serialize and prevent school switching', () async {
    final gateway = FakeSchoolDirectors()..pendingWrite = Completer<void>();
    final controller = SchoolDirectorsController(gateway);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.select(directorSchoolA);
    final write = controller.saveProfile(directorDraft);
    expect(await controller.saveProfile(directorDraft), isFalse);
    await controller.select(directorSchoolB);
    expect(controller.school, directorSchoolA);
    expect(gateway.writes, 1);
    gateway.pendingWrite!.complete();
    expect(await write, isTrue);
    expect(controller.canMutate, isTrue);
  });

  test('confirmed write and failed refresh are distinct; reload never replays write', () async {
    final gateway = FakeSchoolDirectors()..failRefresh = true;
    final controller = SchoolDirectorsController(gateway);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.select(directorSchoolA);
    expect(await controller.saveProfile(directorDraft), isTrue);
    expect(controller.saved, isTrue);
    expect(controller.error, DirectorFailure.network);
    expect(controller.directory, isNull);
    expect(controller.canMutate, isFalse);
    gateway.failRefresh = false;
    await controller.reload();
    expect(gateway.writes, 1);
    expect(controller.canMutate, isTrue);
  });

  test(
    'ambiguous writes clear stale actionable data and require reload',
    () async {
      final gateway = FakeSchoolDirectors()
        ..writeFailure = DirectorFailure.uncertain;
      final controller = SchoolDirectorsController(gateway);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.select(directorSchoolA);
      expect(await controller.saveProfile(directorDraft), isFalse);
      expect(controller.saved, isFalse);
      expect(controller.directory, isNull);
      expect(await controller.saveProfile(directorDraft), isFalse);
      expect(gateway.writes, 1);
    },
  );

  test(
    'validation failure keeps current directory and allows corrected draft',
    () async {
      final gateway = FakeSchoolDirectors()
        ..writeFailure = DirectorFailure.validation;
      final controller = SchoolDirectorsController(gateway);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.select(directorSchoolA);
      expect(await controller.saveProfile(directorDraft), isFalse);
      expect(controller.canMutate, isTrue);
      expect(controller.error, DirectorFailure.validation);
    },
  );

  test('assignment asserts reviewed current ID', () async {
    final gateway = FakeSchoolDirectors();
    final controller = SchoolDirectorsController(gateway);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.select(directorSchoolA);
    expect(await controller.assign(31, DateTime(2026, 10, 24)), isTrue);
    expect(gateway.replacement, 50);
  });

  test(
    'dispose ignores pending read without notifying or mutating state',
    () async {
      final gateway = FakeSchoolDirectors();
      gateway.pendingReads[10] = Completer<DirectorDirectory>();
      final controller = SchoolDirectorsController(gateway);
      await controller.initialize();
      final read = controller.select(directorSchoolA);
      controller.dispose();
      gateway.pendingReads[10]!.complete(directorDirectory());
      await read;
      expect(controller.directory, isNull);
      expect(controller.canMutate, isFalse);
    },
  );
}
