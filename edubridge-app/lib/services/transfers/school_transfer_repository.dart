import '../../model/enrollment/enrollment_models.dart';
import '../../model/transfers/school_transfer.dart';
import '../enrollment/enrollment_api_client.dart';
import '../schools/school_management_repository.dart';

abstract interface class SchoolTransferGateway {
  Future<SchoolTransferDirectory> load();
  Future<int> create(int enrollment, int destination, String reason);
  Future<void> decide(IncomingSchoolTransfer request,
      {required bool accept, int? section, required String key});
}

/// Uses existing consent/destination routes. No automatic write replay.
class SchoolTransferRepository implements SchoolTransferGateway {
  SchoolTransferRepository(
      {required this.schoolId, required SchoolManagementRepository repository})
      : _repository = repository.scoped(schoolId);
  final int schoolId;
  final SchoolManagementRepository _repository;
  Future<void> _authority() async {
    final context = await _repository.context();
    if (!(context['permissions'] as List).contains('enrollment')) {
      throw const EnrollmentApiException(EnrollmentFailure.forbidden);
    }
  }

  T _parse<T>(T Function() read) {
    try {
      return read();
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  List<T> _unique<T>(
      dynamic raw, T Function(Map<String, dynamic>) parse, int Function(T) id) {
    final seen = <int>{};
    return enrollmentList(raw).map((value) {
      final item = parse(enrollmentMap(value));
      if (!seen.add(id(item)))
        throw const FormatException('Duplicate transfer record');
      return item;
    }).toList();
  }

  @override
  Future<SchoolTransferDirectory> load() async {
    await _authority();
    final students = await _repository.operation('students');
    final academics = await _repository.operation('academic');
    final destinations = await _repository.client
        .get('/school/annual-promotion/transfer-schools');
    final incoming = await _repository.client.get('/school/transfers/incoming');
    await _authority();
    return _parse(() {
      for (final response in [students, academics, destinations, incoming]) {
        if (response['success'] == false || response['error'] != null)
          throw const FormatException('Rejected transfer response');
      }
      if (enrollmentId(enrollmentMap(academics['school'])['id']) != schoolId) {
        throw const FormatException('Academic scope mismatch');
      }
      final studentsList = _unique(students['enrollments'], (row) {
        final id = enrollmentId(row['id']);
        final child = enrollmentId(row['child_id']);
        final status = enrollmentText(row['status']);
        return (
          choice: TransferChoice(id,
              '${enrollmentText(row['child_name'])} — ${enrollmentText(row['section_name'])}',
              childId: child),
          active: status == 'active'
        );
      }, (item) => item.choice.id);
      final schools = _unique(destinations['schools'], (row) {
        final id = enrollmentId(row['id']);
        if (id == schoolId)
          throw const FormatException('Source in destinations');
        return TransferChoice(id, enrollmentText(row['name']));
      }, (item) => item.id);
      final sections = _unique(
          academics['sections'],
          (row) => TransferChoice(enrollmentId(row['id']),
              '${enrollmentText(row['academic_year_name'])} — ${enrollmentText(row['grade_name'])} — ${enrollmentText(row['name'])}'),
          (item) => item.id);
      final requests = _unique(
          incoming['requests'],
          (row) => IncomingSchoolTransfer.fromJson(row, schoolId),
          (item) => item.id);
      return SchoolTransferDirectory(
          enrollments: studentsList
              .where((item) => item.active)
              .map((item) => item.choice)
              .toList(),
          schools: schools,
          sections: sections,
          incoming: requests);
    });
  }

  Future<Map<String, dynamic>> _write(String path, Map<String, dynamic> body,
      {int success = 201}) async {
    try {
      return await _repository.client.post(path, body, success: success);
    } on EnrollmentApiException catch (e) {
      if ([
        EnrollmentFailure.invalidResponse,
        EnrollmentFailure.server,
        EnrollmentFailure.network,
        EnrollmentFailure.uncertain
      ].contains(e.failure)) {
        throw const EnrollmentApiException(EnrollmentFailure.uncertain);
      }
      rethrow;
    }
  }

  @override
  Future<int> create(int enrollment, int destination, String reason) async {
    reason = reason.trim();
    if (reason.length > 500)
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    final current = await load();
    if (!current.enrollments.any((row) => row.id == enrollment) ||
        !current.schools.any((row) => row.id == destination)) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    final receipt = await _write('/school/transfers', {
      'source_enrollment_id': enrollment,
      'destination_school_id': destination,
      if (reason.isNotEmpty) 'reason': reason,
    });
    try {
      if (receipt['status'] != 'pending_guardian')
        throw const FormatException('Invalid transfer receipt');
      return enrollmentId(receipt['request_id']);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    }
  }

  @override
  Future<void> decide(IncomingSchoolTransfer request,
      {required bool accept, int? section, required String key}) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]{16,128}$').hasMatch(key)) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final current = await load();
    if (!current.incoming.any((row) =>
            row.id == request.id &&
            row.version == request.version &&
            row.childId == request.childId &&
            row.sourceSchoolId == request.sourceSchoolId) ||
        (accept && !current.sections.any((row) => row.id == section))) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    final receipt = await _write(
        '/school/transfers/${request.id}/decision',
        {
          'decision': accept ? 'accept' : 'reject',
          'version': request.version,
          if (accept) 'section_id': section,
          if (accept) 'idempotency_key': key,
        },
        success: accept ? 201 : 200);
    try {
      if (enrollmentId(receipt['request_id']) != request.id ||
          receipt['status'] !=
              (accept ? 'completed' : 'destination_rejected')) {
        throw const FormatException('Invalid destination receipt');
      }
      if (accept) enrollmentId(receipt['enrollment_id']);
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    }
  }
}
