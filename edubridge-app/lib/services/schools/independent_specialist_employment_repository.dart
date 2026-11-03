import '../../model/enrollment/enrollment_models.dart';
import '../enrollment/enrollment_api_client.dart';

class IndependentSpecialistEmployment {
  IndependentSpecialistEmployment({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.specialistId,
    required this.specialistName,
    required this.email,
    required this.accepted,
  });

  final int id;
  final int schoolId;
  final String schoolName;
  final int specialistId;
  final String specialistName;
  final String email;
  final bool accepted;
}

abstract interface class IndependentSpecialistEmploymentGateway {
  Future<List<IndependentSpecialistEmployment>> directorRoster(int schoolId);
  Future<void> invite(int schoolId, String email);
  Future<void> end(int schoolId, int employmentId);
  Future<List<IndependentSpecialistEmployment>> myOffers();
  Future<void> accept(int employmentId);
}

class IndependentSpecialistEmploymentRepository
    implements IndependentSpecialistEmploymentGateway {
  IndependentSpecialistEmploymentRepository({EnrollmentApiClient? client})
      : _client = client ?? EnrollmentApiClient();

  final EnrollmentApiClient _client;

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }

  Future<int> _identity() async {
    final data = await _client.get('/me');
    return _parse(() {
      final me = enrollmentMap(data['user']);
      if (me['role'] != 'specialist') {
        throw const EnrollmentApiException(EnrollmentFailure.forbidden);
      }
      return enrollmentId(me['id']);
    });
  }

  Future<void> _schoolDirector(int schoolId) async {
    final identity = await _client.get('/school/context');
    _parse(() {
      final school = enrollmentMap(identity['school']);
      if (enrollmentId(school['id']) != schoolId ||
          !school.containsKey('organization_id') ||
          school['organization_id'] != null) {
        throw const FormatException('Director not scoped to independent school');
      }
    });
    final delegation = await _client.get('/school/delegation');
    _parse(() {
      final school = enrollmentMap(delegation['school']);
      if (enrollmentId(school['id']) != schoolId ||
          delegation['role'] != 'director') {
        throw const FormatException('Director assignment unavailable');
      }
    });
  }

  @override
  Future<List<IndependentSpecialistEmployment>> directorRoster(int schoolId) async {
    await _schoolDirector(schoolId);
    final data = await _client.get('/school/specialist-employments');
    await _schoolDirector(schoolId);
    return _parse(() {
      if (enrollmentId(data['school_id']) != schoolId ||
          data['complete'] != true) {
        throw const FormatException('Wrong school employment roster');
      }
      final rows = enrollmentList(data['employments']);
      final ids = <int>{};
      return List.unmodifiable(rows.map((item) {
        final row = enrollmentMap(item);
        final id = enrollmentId(row['id']);
        if (!ids.add(id) || !row.containsKey('ended_at') ||
            !row.containsKey('accepted_at')) {
          throw const FormatException('Invalid employment record');
        }
        return IndependentSpecialistEmployment(
          id: id,
          schoolId: schoolId,
          schoolName: '',
          specialistId: enrollmentId(row['specialist_id']),
          specialistName: enrollmentText(row['specialist_name']),
          email: enrollmentText(row['specialist_email']),
          accepted: row['accepted_at'] != null && row['ended_at'] == null,
        );
      }));
    });
  }

  @override
  Future<void> invite(int schoolId, String email) async {
    final normalized = email.trim().toLowerCase();
    if (schoolId < 1 || !normalized.contains('@') || normalized.length > 190) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    await _schoolDirector(schoolId);
    final receipt = await _client.post('/school/specialist-employments', {
      'expected_school_id': schoolId,
      'email': normalized,
    });
    _parse(() {
      if (enrollmentId(receipt['school_id']) != schoolId ||
          receipt['status'] != 'pending') {
        throw const FormatException('Foreign specialist employment receipt');
      }
      enrollmentId(receipt['employment_id']);
    });
  }

  @override
  Future<void> end(int schoolId, int employmentId) async {
    if (employmentId < 1) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    await _schoolDirector(schoolId);
    final current = await directorRoster(schoolId);
    if (!current.any((row) => row.id == employmentId)) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    final receipt = await _client.post(
      '/school/specialist-employments/$employmentId/end',
      {'expected_school_id': schoolId}, success: 200);
    _parse(() {
      if (enrollmentId(receipt['school_id']) != schoolId ||
          enrollmentId(receipt['employment_id']) != employmentId ||
          receipt['ended'] != true) {
        throw const FormatException('Foreign employment termination receipt');
      }
    });
  }

  @override
  Future<List<IndependentSpecialistEmployment>> myOffers() async {
    final user = await _identity();
    final data = await _client.get('/specialists/me/school-employments');
    if (await _identity() != user) {
      throw const EnrollmentApiException(EnrollmentFailure.session);
    }
    return _parse(() {
      if (data['complete'] != true ||
          enrollmentId(data['specialist_id']) != user) {
        throw const FormatException('Foreign specialist offers');
      }
      final ids = <int>{};
      return List.unmodifiable(enrollmentList(data['employments']).map((item) {
        final row = enrollmentMap(item);
        final id = enrollmentId(row['id']);
        if (!ids.add(id) || !row.containsKey('accepted_at')) {
          throw const FormatException('Duplicate specialist offer');
        }
        return IndependentSpecialistEmployment(
          id: id,
          schoolId: enrollmentId(row['school_id']),
          schoolName: enrollmentText(row['school_name']),
          specialistId: user,
          specialistName: '',
          email: '',
          accepted: row['accepted_at'] != null,
        );
      }));
    });
  }

  @override
  Future<void> accept(int employmentId) async {
    if (employmentId < 1) {
      throw const EnrollmentApiException(EnrollmentFailure.validation);
    }
    final offers = await myOffers();
    final offer = offers.where((item) => item.id == employmentId && !item.accepted);
    if (offer.length != 1) {
      throw const EnrollmentApiException(EnrollmentFailure.conflict);
    }
    final receipt = await _client.post(
      '/specialists/me/school-employments/$employmentId/accept',
      {}, success: 200);
    _parse(() {
      if (enrollmentId(receipt['school_id']) != offer.single.schoolId ||
          enrollmentId(receipt['employment_id']) != employmentId ||
          receipt['status'] != 'active') {
        throw const FormatException('Foreign acceptance receipt');
      }
    });
    final after = await myOffers();
    if (!after.any((item) => item.id == employmentId && item.accepted)) {
      throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
    }
  }
}
