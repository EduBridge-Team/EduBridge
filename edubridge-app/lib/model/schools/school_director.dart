/// Values accepted by the Flutter-owned director API contract.
int parseDirectorId(dynamic value) {
  if (value is! int || value <= 0) throw const FormatException('Invalid ID');
  return value;
}

String directorText(dynamic value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Missing text');
  }
  return value;
}

DateTime directorDate(dynamic value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('Invalid date');
  }
  final date = DateTime.tryParse(value);
  if (date == null || directorDateString(date) != value) {
    throw const FormatException('Invalid calendar date');
  }
  return date;
}

String directorDateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class DirectorSchool {
  const DirectorSchool({
    required this.id,
    required this.name,
    required this.organizationId,
    required this.organizationSlug,
  });
  final int id;
  final String name;
  final int organizationId;
  final String organizationSlug;

  String get path => '/institutions/$organizationSlug/schools/$id';
}

class DirectorDraft {
  const DirectorDraft({
    required this.name,
    required this.email,
    required this.phone,
    required this.qualification,
    required this.experienceYears,
  });
  final String name;
  final String email;
  final String phone;
  final String qualification;
  final int experienceYears;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'email': email.trim(),
    'phone': phone.trim(),
    'qualification': qualification.trim(),
    'experience_years': experienceYears,
  };
}

class SchoolDirector {
  const SchoolDirector({
    required this.id,
    required this.schoolId,
    required this.details,
  });
  final int id;
  final int schoolId;
  final DirectorDraft details;

  factory SchoolDirector.fromJson(Map<String, dynamic> data) {
    final experience = data['experience_years'];
    if (experience is! int ||
        experience < 0 ||
        experience > 80 ||
        data['phone'] is! String ||
        data['qualification'] is! String) {
      throw const FormatException('Invalid director details');
    }
    return SchoolDirector(
      id: parseDirectorId(data['id']),
      schoolId: parseDirectorId(data['school_id']),
      details: DirectorDraft(
        name: directorText(data['name']),
        email: directorText(data['email']),
        phone: data['phone'] as String,
        qualification: data['qualification'] as String,
        experienceYears: experience,
      ),
    );
  }
}

class DirectorAssignment {
  const DirectorAssignment({
    required this.id,
    required this.schoolId,
    required this.directorId,
    required this.startsOn,
    required this.endedOn,
  });
  final int id;
  final int schoolId;
  final int directorId;
  final DateTime startsOn;
  final DateTime? endedOn;
  bool get isActive => endedOn == null;

  factory DirectorAssignment.fromJson(Map<String, dynamic> data) {
    final start = directorDate(data['starts_on']);
    if (!data.containsKey('ended_on'))
      throw const FormatException('Missing end date');
    final end = data['ended_on'] == null
        ? null
        : directorDate(data['ended_on']);
    if (end != null && end.isBefore(start))
      throw const FormatException('Invalid interval');
    return DirectorAssignment(
      id: parseDirectorId(data['id']),
      schoolId: parseDirectorId(data['school_id']),
      directorId: parseDirectorId(data['director_id']),
      startsOn: start,
      endedOn: end,
    );
  }
}

class DirectorDirectory {
  DirectorDirectory({
    required List<SchoolDirector> directors,
    required List<DirectorAssignment> assignments,
  }) : directors = List.unmodifiable(directors),
       assignments = List.unmodifiable(assignments);
  final List<SchoolDirector> directors;
  final List<DirectorAssignment> assignments;
  DirectorAssignment? get current {
    for (final assignment in assignments) {
      if (assignment.isActive) return assignment;
    }
    return null;
  }
}
