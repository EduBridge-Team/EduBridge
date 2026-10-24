import 'dart:async';

import 'package:edubridge_app/model/schools/school_director.dart';
import 'package:edubridge_app/services/schools/director_api_client.dart';
import 'package:edubridge_app/services/schools/school_director_repository.dart';

const directorSchoolA = DirectorSchool(
  id: 10,
  name: 'School A',
  organizationId: 4,
  organizationSlug: 'demo-institution',
);
const directorSchoolB = DirectorSchool(
  id: 20,
  name: 'School B',
  organizationId: 4,
  organizationSlug: 'demo-institution',
);
const directorDraft = DirectorDraft(
  name: 'Noor',
  email: 'director@example.org',
  phone: '123',
  qualification: 'Education',
  experienceYears: 5,
);
const directorProfile = SchoolDirector(
  id: 30,
  schoolId: 10,
  details: directorDraft,
);
DirectorDirectory directorDirectory({bool active = true}) => DirectorDirectory(
  directors: [directorProfile],
  assignments: active
      ? [
          DirectorAssignment(
            id: 50,
            schoolId: 10,
            directorId: 30,
            startsOn: DateTime(2026, 10, 1),
            endedOn: null,
          ),
        ]
      : [],
);

class FakeSchoolDirectors implements SchoolDirectorGateway {
  List<DirectorSchool> schoolResults = [directorSchoolA, directorSchoolB];
  DirectorFailure? loadFailure;
  DirectorFailure? writeFailure;
  bool failRefresh = false;
  bool wrote = false;
  Completer<void>? pendingWrite;
  final pendingReads = <int, Completer<DirectorDirectory>>{};
  int writes = 0;
  int reads = 0;
  int? replacement;
  DirectorDraft? lastDraft;
  int? editedId;
  String? lastOperation;

  @override
  Future<List<DirectorSchool>> schools() async => schoolResults;
  @override
  Future<DirectorDirectory> directory(DirectorSchool school) async {
    reads++;
    if (loadFailure != null) throw DirectorApiException(loadFailure!);
    if (wrote && failRefresh)
      throw const DirectorApiException(DirectorFailure.network);
    if (pendingReads.containsKey(school.id))
      return pendingReads[school.id]!.future;
    return school.id == 10
        ? directorDirectory()
        : DirectorDirectory(directors: [], assignments: []);
  }

  Future<void> _write(String operation) async {
    writes++;
    lastOperation = operation;
    if (pendingWrite != null) await pendingWrite!.future;
    if (writeFailure != null) throw DirectorApiException(writeFailure!);
    wrote = true;
  }

  @override
  Future<void> save(
    DirectorSchool school,
    DirectorDraft draft, {
    int? directorId,
  }) async {
    lastDraft = draft;
    editedId = directorId;
    await _write('save');
  }

  @override
  Future<void> assign(
    DirectorSchool school,
    int directorId,
    DateTime startsOn, {
    int? replacesAssignmentId,
  }) async {
    replacement = replacesAssignmentId;
    await _write('assign');
  }

  @override
  Future<void> end(
    DirectorSchool school,
    DirectorAssignment assignment,
    DateTime endedOn,
  ) => _write('end');
}
