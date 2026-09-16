// models/care_team_model.dart
enum SpecialistSpecialty {
  psychological,
  educational,
  speech,
  behavioral,
}

extension SpecialistSpecialtyX on SpecialistSpecialty {
  String get label {
    switch (this) {
      case SpecialistSpecialty.psychological:
        return 'دعم نفسي';
      case SpecialistSpecialty.educational:
        return 'خطط تعلم';
      case SpecialistSpecialty.speech:
        return 'تخاطب ونطق';
      case SpecialistSpecialty.behavioral:
        return 'تعديل سلوك';
    }
  }

  String get emoji {
    switch (this) {
      case SpecialistSpecialty.psychological:
        return '🧠';
      case SpecialistSpecialty.educational:
        return '📚';
      case SpecialistSpecialty.speech:
        return '🗣️';
      case SpecialistSpecialty.behavioral:
        return '🎯';
    }
  }
}

class CareTeamMember {
  final int userId;
  final String name;
  final String role;
  final SpecialistSpecialty? specialty;
  final String? subject;
  final DateTime assignedAt;

  CareTeamMember({
    required this.userId,
    required this.name,
    required this.role,
    this.specialty,
    this.subject,
    required this.assignedAt,
  });

  factory CareTeamMember.fromJson(Map<String, dynamic> json) =>
      CareTeamMember(
        userId: json['user_id'],
        name: json['name'] ?? '',
        role: json['role'] ?? '',
        specialty: json['specialty'] != null
            ? SpecialistSpecialty.values.firstWhere(
                (e) => e.name == json['specialty'],
                orElse: () => SpecialistSpecialty.psychological,
              )
            : null,
        subject: json['subject'],
        assignedAt: DateTime.parse(json['assigned_at']),
      );
}

class CareTeam {
  final int childId;
  final List<CareTeamMember> members;

  CareTeam({required this.childId, required this.members});

  List<CareTeamMember> get teachers =>
      members.where((m) => m.role == 'teacher').toList();

  List<CareTeamMember> get specialists =>
      members.where((m) => m.role == 'specialist').toList();

  int get teacherCount => teachers.length;

  List<String> get subjects =>
      teachers.map((t) => t.subject ?? 'عام').toSet().toList();

  factory CareTeam.fromJson(Map<String, dynamic> json) => CareTeam(
        childId: json['child_id'],
        members: (json['members'] as List? ?? [])
            .map((e) => CareTeamMember.fromJson(e))
            .toList(),
      );
}