import '../../model/schools/school_director.dart';
import 'director_api_client.dart';

abstract interface class SchoolDirectorGateway {
  Future<List<DirectorSchool>> schools();
  Future<DirectorDirectory> directory(DirectorSchool school);
  Future<void> save(
    DirectorSchool school,
    DirectorDraft draft, {
    int? directorId,
  });
  Future<void> assign(
    DirectorSchool school,
    int directorId,
    DateTime startsOn, {
    int? replacesAssignmentId,
  });
  Future<void> end(
    DirectorSchool school,
    DirectorAssignment assignment,
    DateTime endedOn,
  );
}

class SchoolDirectorRepository implements SchoolDirectorGateway {
  SchoolDirectorRepository({DirectorApiClient? client})
    : _client = client ?? DirectorApiClient();
  final DirectorApiClient _client;

  T _parse<T>(T Function() read) {
    try {
      return read();
    } on FormatException {
      throw const DirectorApiException(DirectorFailure.invalidResponse);
    }
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is! Map<String, dynamic>)
      throw const FormatException('Expected object');
    return value;
  }

  List<dynamic> _list(dynamic value) {
    if (value is! List) throw const FormatException('Expected list');
    return value;
  }

  @override
  Future<List<DirectorSchool>> schools() async {
    final context = await _client.get('/institutions/my-organization');
    final organization = _parse(() => _map(context['organization']));
    final id = _parse(() => parseDirectorId(organization['id']));
    final slug = _parse(() => directorText(organization['slug']));
    if (!RegExp(r'^[a-z0-9][a-z0-9-]{1,79}$').hasMatch(slug)) {
      throw const DirectorApiException(DirectorFailure.invalidResponse);
    }
    final data = await _client.get('/institutions/$slug/schools');
    return _parse(() {
      final seen = <int>{};
      return List.unmodifiable(
        _list(data['schools']).map((value) {
          final school = _map(value);
          final schoolId = parseDirectorId(school['id']);
          if (parseDirectorId(school['organization_id']) != id ||
              !seen.add(schoolId)) {
            throw const FormatException('School scope mismatch');
          }
          return DirectorSchool(
            id: schoolId,
            name: directorText(school['name']),
            organizationId: id,
            organizationSlug: slug,
          );
        }),
      );
    });
  }

  @override
  Future<DirectorDirectory> directory(DirectorSchool school) async {
    final data = await _client.get('${school.path}/directors');
    return _parse(() {
      if (parseDirectorId(data['school_id']) != school.id)
        throw const FormatException('Wrong school');
      final directors = _list(data['directors'])
          .map((v) => SchoolDirector.fromJson(_map(v)))
          .toList();
      final assignments = _list(data['assignments'])
          .map((v) => DirectorAssignment.fromJson(_map(v)))
          .toList();
      final ids = directors.map((d) => d.id).toSet();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (ids.length != directors.length ||
          directors.any((d) => d.schoolId != school.id) ||
          assignments.any(
            (a) => a.schoolId != school.id || !ids.contains(a.directorId),
          ) ||
          assignments.map((a) => a.id).toSet().length != assignments.length ||
          assignments.where((a) => a.isActive).length > 1 ||
          assignments.any(
            (a) =>
                a.startsOn.isAfter(today) ||
                (a.endedOn?.isAfter(today) ?? false),
          )) {
        throw const FormatException('Invalid directory scope or history');
      }
      assignments.sort((a, b) => b.startsOn.compareTo(a.startsOn));
      // Historical periods may meet on a handover date, but must not overlap.
      for (var i = 0; i + 1 < assignments.length; i++) {
        final newer = assignments[i];
        final older = assignments[i + 1];
        if (older.endedOn == null ||
            older.endedOn!.isAfter(newer.startsOn)) {
          throw const FormatException('Overlapping director appointments');
        }
      }
      return DirectorDirectory(directors: directors, assignments: assignments);
    });
  }

  @override
  Future<void> save(
    DirectorSchool school,
    DirectorDraft draft, {
    int? directorId,
  }) async {
    final data = directorId == null
        ? await _client.post('${school.path}/directors', draft.toJson())
        : await _client.patch(
            '${school.path}/directors/$directorId',
            draft.toJson(),
          );
    _parse(() {
      final profile = SchoolDirector.fromJson(_map(data['director']));
      if (profile.schoolId != school.id ||
          (directorId != null && profile.id != directorId) ||
          !profile.details.matches(draft)) {
        throw const FormatException('Director response mismatch');
      }
    });
  }

  @override
  Future<void> assign(
    DirectorSchool school,
    int directorId,
    DateTime startsOn, {
    int? replacesAssignmentId,
  }) async {
    final data = await _client.post('${school.path}/director-assignments', {
      'director_id': directorId,
      'starts_on': directorDateString(startsOn),
      'replace_assignment_id': replacesAssignmentId,
    });
    _parse(() {
      final assignment = DirectorAssignment.fromJson(_map(data['assignment']));
      if (assignment.schoolId != school.id ||
          assignment.directorId != directorId ||
          !assignment.isActive ||
          assignment.startsOn != directorDate(directorDateString(startsOn))) {
        throw const FormatException('Assignment response mismatch');
      }
    });
  }

  @override
  Future<void> end(
    DirectorSchool school,
    DirectorAssignment assignment,
    DateTime endedOn,
  ) async {
    final data = await _client.patch(
      '${school.path}/director-assignments/${assignment.id}/end',
      {
        'ended_on': directorDateString(endedOn),
        'expected_director_id': assignment.directorId,
      },
    );
    _parse(() {
      final result = DirectorAssignment.fromJson(_map(data['assignment']));
      if (result.schoolId != school.id ||
          result.id != assignment.id ||
          result.directorId != assignment.directorId ||
          result.startsOn != assignment.startsOn ||
          result.isActive ||
          result.endedOn != directorDate(directorDateString(endedOn))) {
        throw const FormatException('End assignment response mismatch');
      }
    });
  }
}
