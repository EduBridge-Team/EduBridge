// models/care_team_model.dart
import 'package:flutter/material.dart';
import '../app_icons.dart'; // عدّل المسار حسب مكان الملف

enum SpecialistSpecialty {
  learningSupport,
  educational,
  communicationSupport,
  learningBehavior,
}

extension SpecialistSpecialtyX on SpecialistSpecialty {
  String get apiValue {
    switch (this) {
      case SpecialistSpecialty.learningSupport:
        return 'learning_support';
      case SpecialistSpecialty.educational:
        return 'educational';
      case SpecialistSpecialty.communicationSupport:
        return 'communication_support';
      case SpecialistSpecialty.learningBehavior:
        return 'learning_behavior';
    }
  }

  String get label {
    switch (this) {
      case SpecialistSpecialty.learningSupport:
        return 'دعم تعليمي';
      case SpecialistSpecialty.educational:
        return 'خطط تعلم';
      case SpecialistSpecialty.communicationSupport:
        return 'دعم التواصل التعليمي';
      case SpecialistSpecialty.learningBehavior:
        return 'دعم سلوك التعلم';
    }
  }

  IconData get icon {
    switch (this) {
      case SpecialistSpecialty.learningSupport:
        return AppIcons.lesson;
      case SpecialistSpecialty.educational:
        return AppIcons.plan;
      case SpecialistSpecialty.communicationSupport:
        return AppIcons.forum;
      case SpecialistSpecialty.learningBehavior:
        return AppIcons.evaluate;
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
                (e) => e.apiValue == json['specialty'],
                orElse: () => SpecialistSpecialty.learningSupport,
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