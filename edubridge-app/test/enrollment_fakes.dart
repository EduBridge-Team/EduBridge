import 'dart:async';

import 'package:edubridge_app/model/enrollment/enrollment_models.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/enrollment/enrollment_repository.dart';

const enrollmentSchool = EnrollmentSchool(
  id: 10,
  name: 'School A',
  address: 'Gaza',
);
const enrollmentSection = EnrollmentSection(
  id: 20,
  name: 'A',
  gradeName: 'Grade 2',
  academicYearId: 3,
  academicYearName: '2026/2027',
);
EnrollmentRequest enrollmentRequest({
  EnrollmentStatus status = EnrollmentStatus.pending,
  int version = 1,
}) => EnrollmentRequest(
  id: 50,
  schoolId: 10,
  schoolName: 'School A',
  childId: 6,
  childName: 'Child A',
  status: status,
  version: version,
  createdAt: DateTime.utc(2026, 10, 24),
  reason: status == EnrollmentStatus.rejected ? 'Full capacity' : null,
);
Map<String, dynamic> enrollmentRequestJson({
  String status = 'pending',
  int version = 1,
}) => {
  'id': 50,
  'school_id': 10,
  'school_name': 'School A',
  'child_id': 6,
  'child_name': 'Child A',
  'status': status,
  'version': version,
  'created_at': '2026-10-24T10:00:00Z',
  'reason': status == 'rejected' ? 'Full capacity' : null,
};
Map<String, dynamic> activeEnrollmentJson() => {
  'id': 90,
  'school_id': 10,
  'school_name': 'School A',
  'child_id': 6,
  'section_id': 20,
  'status': 'active',
};

class FakeSchoolEnrollment implements SchoolEnrollmentGateway {
  List<EnrollmentRequest> requests = [enrollmentRequest()];
  List<EnrollmentSection> sections = [enrollmentSection];
  EnrollmentFailure? loadFailure;
  EnrollmentFailure? writeFailure;
  bool failRefresh = false;
  int writes = 0;
  Completer<void>? pendingWrite;
  Completer<SchoolEnrollmentInbox>? pendingRead;
  EnrollmentDecision? lastDecision;
  @override
  Future<SchoolEnrollmentInbox> load() async {
    if (loadFailure != null || (writes > 0 && failRefresh))
      throw EnrollmentApiException(loadFailure ?? EnrollmentFailure.network);
    if (pendingRead != null) return pendingRead!.future;
    return SchoolEnrollmentInbox(
      identity: const SchoolPortalIdentity(
        school: enrollmentSchool,
        organizationId: null,
      ),
      requests: requests,
      sections: sections,
    );
  }

  @override
  Future<void> decide(
    EnrollmentRequest request,
    EnrollmentDecision decision,
  ) async {
    writes++;
    lastDecision = decision;
    if (pendingWrite != null) await pendingWrite!.future;
    if (writeFailure != null) throw EnrollmentApiException(writeFailure!);
    requests = [
      enrollmentRequest(
        status: decision.approve
            ? EnrollmentStatus.approved
            : EnrollmentStatus.rejected,
        version: 2,
      ),
    ];
  }
}

class FakeParentEnrollment implements ParentEnrollmentGateway {
  List<EnrollmentRequest> requests = [];
  ActiveSchoolEnrollment? active;
  EnrollmentFailure? loadFailure;
  EnrollmentFailure? writeFailure;
  bool failRefresh = false;
  int writes = 0;
  int searches = 0;
  final pendingSearch = <String, Completer<List<EnrollmentSchool>>>{};
  Completer<void>? pendingWrite;
  @override
  Future<ParentEnrollmentHistory> load() async {
    if (loadFailure != null || (writes > 0 && failRefresh))
      throw EnrollmentApiException(loadFailure ?? EnrollmentFailure.network);
    return ParentEnrollmentHistory(
      requests: requests,
      activeEnrollment: active,
    );
  }

  @override
  Future<List<EnrollmentSchool>> search(String query) async {
    searches++;
    if (pendingSearch.containsKey(query)) return pendingSearch[query]!.future;
    return [enrollmentSchool];
  }

  @override
  Future<void> submit(EnrollmentSchool school) async {
    writes++;
    if (pendingWrite != null) await pendingWrite!.future;
    if (writeFailure != null) throw EnrollmentApiException(writeFailure!);
    requests = [enrollmentRequest()];
  }

  @override
  Future<void> cancel(EnrollmentRequest request) async {
    writes++;
    requests = [
      enrollmentRequest(status: EnrollmentStatus.cancelled, version: 2),
    ];
  }
}
