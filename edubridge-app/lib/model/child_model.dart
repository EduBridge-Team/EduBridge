// نموذج بيانات الطفل
class Child {
  final int id;
  final String name;
  final int age;
  final String? disabilityType;
  final String? disabilityDescription;
  final String? medicalHistory;
  final String? psychologistNotes;
  final String? specialNeeds;
  final String? preferredLearningStyle;
  final List<String>? strengths;
  final List<String>? challenges;
  final String? status; // pending, evaluated, assigned
  final int? assignedTeacherId;
  final String? teacherName;
  final DateTime createdAt;
  final DateTime? evaluatedAt;

  Child({
    required this.id,
    required this.name,
    required this.age,
    this.disabilityType,
    this.disabilityDescription,
    this.medicalHistory,
    this.psychologistNotes,
    this.specialNeeds,
    this.preferredLearningStyle,
    this.strengths,
    this.challenges,
    this.status,
    this.assignedTeacherId,
    this.teacherName,
    required this.createdAt,
    this.evaluatedAt,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'],
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      disabilityType: json['disability_type'],
      disabilityDescription: json['disability_description'],
      medicalHistory: json['medical_history'],
      psychologistNotes: json['psychologist_notes'],
      specialNeeds: json['special_needs'],
      preferredLearningStyle: json['preferred_learning_style'],
      strengths: json['strengths'] != null ? List<String>.from(json['strengths']) : null,
      challenges: json['challenges'] != null ? List<String>.from(json['challenges']) : null,
      status: json['status'],
      assignedTeacherId: json['assigned_teacher_id'],
      teacherName: json['teacher_name'],
      createdAt: DateTime.parse(json['created_at']),
      evaluatedAt: json['evaluated_at'] != null ? DateTime.parse(json['evaluated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'disability_type': disabilityType,
      'disability_description': disabilityDescription,
      'medical_history': medicalHistory,
      'psychologist_notes': psychologistNotes,
      'special_needs': specialNeeds,
      'preferred_learning_style': preferredLearningStyle,
      'strengths': strengths,
      'challenges': challenges,
      'status': status,
      'assigned_teacher_id': assignedTeacherId,
      'teacher_name': teacherName,
      'created_at': createdAt.toIso8601String(),
      'evaluated_at': evaluatedAt?.toIso8601String(),
    };
  }
}