import '../../model/enrollment/enrollment_models.dart';
import 'enrollment_api_client.dart';

abstract interface class SchoolEnrollmentGateway {
  Future<SchoolEnrollmentInbox> load();
  Future<void> decide(EnrollmentRequest request, EnrollmentDecision decision);
}

abstract interface class ParentEnrollmentGateway {
  Future<ParentEnrollmentHistory> load();
  Future<List<EnrollmentSchool>> search(String query);
  Future<void> submit(EnrollmentSchool school);
  Future<void> cancel(EnrollmentRequest request);
}

T _parse<T>(T Function() read) {
  try {
    return read();
  } on FormatException {
    throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
  }
}

List<EnrollmentRequest> _requests(dynamic data) {
  final items = enrollmentList(data)
      .map((v) => EnrollmentRequest.fromJson(enrollmentMap(v)))
      .toList();
  if (items.map((r) => r.id).toSet().length != items.length) {
    throw const FormatException('Duplicate request IDs');
  }
  return items;
}

void _changed(
  EnrollmentRequest original,
  EnrollmentRequest result,
  EnrollmentStatus status,
) {
  if (result.id != original.id ||
      result.schoolId != original.schoolId ||
      result.childId != original.childId ||
      result.version != original.version + 1 ||
      result.schoolName != original.schoolName ||
      result.childName != original.childName ||
      !result.createdAt.isAtSameMomentAs(original.createdAt) ||
      result.status != status) {
    throw const FormatException('Request response mismatch');
  }
}

class SchoolEnrollmentRepository implements SchoolEnrollmentGateway {
  SchoolEnrollmentRepository({EnrollmentApiClient? client})
    : _client = client ?? EnrollmentApiClient();
  final EnrollmentApiClient _client;
  @override
  Future<SchoolEnrollmentInbox> load() async {
    final context = await _client.get('/school/context');
    final identity = _parse(
      () => SchoolPortalIdentity.fromJson(enrollmentMap(context['school'])),
    );
    final results = await Future.wait([
      _client.get('/school/enrollment-requests'),
      _client.get('/school/enrollment-options'),
    ]);
    return _parse(() {
      if (enrollmentId(results[0]['school_id']) != identity.school.id ||
          enrollmentId(results[1]['school_id']) != identity.school.id) {
        throw const FormatException('School scope mismatch');
      }
      final requests = _requests(results[0]['requests']);
      if (requests.any((r) => r.schoolId != identity.school.id)) {
        throw const FormatException('Foreign request');
      }
      final sections = enrollmentList(results[1]['sections'])
          .map((s) => EnrollmentSection.fromJson(enrollmentMap(s)))
          .toList();
      if (sections.map((s) => s.id).toSet().length != sections.length) {
        throw const FormatException('Duplicate sections');
      }
      return SchoolEnrollmentInbox(
        identity: identity,
        requests: requests,
        sections: sections,
      );
    });
  }

  @override
  Future<void> decide(
    EnrollmentRequest request,
    EnrollmentDecision decision,
  ) async {
    if (request.status != EnrollmentStatus.pending ||
        (decision.approve
            ? decision.sectionId == null
            : decision.reason.trim().isEmpty)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final data = await _client.post(
      '/school/enrollment-requests/${request.id}/decision',
      {
        'expected_version': request.version,
        'decision': decision.approve ? 'approved' : 'rejected',
        'section_id': decision.approve ? decision.sectionId : null,
        'reason': decision.reason.trim(),
      },
      success: 200,
    );
    _parse(() {
      final result = EnrollmentRequest.fromJson(enrollmentMap(data['request']));
      _changed(
        request,
        result,
        decision.approve
            ? EnrollmentStatus.approved
            : EnrollmentStatus.rejected,
      );
      if (decision.approve) {
        final enrollment = ActiveSchoolEnrollment.fromJson(
          enrollmentMap(data['enrollment']),
        );
        if (enrollment.childId != request.childId ||
            enrollment.schoolId != request.schoolId ||
            enrollment.sectionId != decision.sectionId) {
          throw const FormatException('Enrollment mismatch');
        }
      } else if (data['enrollment'] != null ||
          result.reason?.trim() != decision.reason.trim()) {
        throw const FormatException('Rejection mismatch');
      }
    });
  }
}

class ParentEnrollmentRepository implements ParentEnrollmentGateway {
  ParentEnrollmentRepository({
    required this.childId,
    EnrollmentApiClient? client,
  }) : _client = client ?? EnrollmentApiClient();
  final int childId;
  final EnrollmentApiClient _client;
  String get _path => '/parent/children/$childId/enrollment-requests';
  @override
  Future<ParentEnrollmentHistory> load() async {
    final data = await _client.get(_path);
    return _parse(() {
      if (enrollmentId(data['child_id']) != childId ||
          !data.containsKey('active_enrollment')) {
        throw const FormatException('Child scope mismatch');
      }
      final requests = _requests(data['requests']);
      final active = data['active_enrollment'] == null
          ? null
          : ActiveSchoolEnrollment.fromJson(
              enrollmentMap(data['active_enrollment']),
            );
      if (requests.any((r) => r.childId != childId) ||
          (active != null && active.childId != childId) ||
          requests.where((r) => r.status == EnrollmentStatus.pending).length >
              1) {
        throw const FormatException('Invalid child history');
      }
      return ParentEnrollmentHistory(
        requests: requests,
        activeEnrollment: active,
      );
    });
  }

  @override
  Future<List<EnrollmentSchool>> search(String query) async {
    final value = query.trim();
    if (value.length < 2 || value.length > 100) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final data = await _client.get(
      '/parent/enrollment-schools?q=${Uri.encodeQueryComponent(value)}',
    );
    return _parse(() {
      final schools = enrollmentList(data['schools'])
          .map((s) => EnrollmentSchool.fromJson(enrollmentMap(s)))
          .toList();
      if (schools.length > 50 ||
          schools.map((s) => s.id).toSet().length != schools.length) {
        throw const FormatException('Invalid school search');
      }
      return List.unmodifiable(schools);
    });
  }

  @override
  Future<void> submit(EnrollmentSchool school) async {
    final data = await _client.post(_path, {'school_id': school.id});
    _parse(() {
      final result = EnrollmentRequest.fromJson(enrollmentMap(data['request']));
      if (result.childId != childId ||
          result.schoolId != school.id ||
          result.status != EnrollmentStatus.pending ||
          result.version != 1) {
        throw const FormatException('Submission mismatch');
      }
    });
  }

  @override
  Future<void> cancel(EnrollmentRequest request) async {
    if (request.childId != childId ||
        request.status != EnrollmentStatus.pending) {
      throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    }
    final data = await _client.post('$_path/${request.id}/cancel', {
      'expected_version': request.version,
    }, success: 200);
    _parse(
      () => _changed(
        request,
        EnrollmentRequest.fromJson(enrollmentMap(data['request'])),
        EnrollmentStatus.cancelled,
      ),
    );
  }
}
