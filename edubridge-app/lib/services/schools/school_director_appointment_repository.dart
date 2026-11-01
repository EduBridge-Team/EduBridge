import '../../model/schools/school_director.dart';
import 'director_api_client.dart';
import 'school_director_repository.dart';

class PersonalSchoolDirector {
  const PersonalSchoolDirector(this.id, this.name, this.email);
  final int id;
  final String name, email;

  factory PersonalSchoolDirector.fromJson(Map<String, dynamic> value) =>
      PersonalSchoolDirector(
        parseDirectorId(value['id']),
        directorText(value['name']),
        directorText(value['email']),
      );
}

abstract interface class SchoolDirectorAppointmentGateway {
  Future<List<DirectorSchool>> schools();
  Future<PersonalSchoolDirector?> current(DirectorSchool school);
  Future<int> appoint(DirectorSchool school, String email);
}

/// Appointments attach an existing verified personal account to a school.
class SchoolDirectorAppointmentRepository
    implements SchoolDirectorAppointmentGateway {
  SchoolDirectorAppointmentRepository({DirectorApiClient? client})
      : _client = client ?? DirectorApiClient();
  final DirectorApiClient _client;

  @override
  Future<List<DirectorSchool>> schools() =>
      SchoolDirectorRepository(client: _client).schools();

  T _parse<T>(T Function() read) {
    try {
      return read();
    } on FormatException {
      throw const DirectorApiException(DirectorFailure.invalidResponse);
    }
  }

  @override
  Future<PersonalSchoolDirector?> current(DirectorSchool school) async {
    final value = await _client.get('/admin/schools/${school.id}/director');
    return _parse(() {
      if (parseDirectorId(value['school_id']) != school.id ||
          !value.containsKey('director')) {
        throw const FormatException('Wrong school or missing director');
      }
      final director = value['director'];
      if (director == null) return null;
      if (director is! Map<String, dynamic>) {
        throw const FormatException('Invalid director');
      }
      return PersonalSchoolDirector.fromJson(director);
    });
  }

  @override
  Future<int> appoint(DirectorSchool school, String email) async {
    final value = await _client.post(
        '/admin/schools/${school.id}/director',
        {
          'director_email': email.trim().toLowerCase(),
        },
        expectedStatus: 200);
    return _parse(() {
      if (parseDirectorId(value['school_id']) != school.id) {
        throw const FormatException('Wrong school');
      }
      return parseDirectorId(value['director_user_id']);
    });
  }
}
