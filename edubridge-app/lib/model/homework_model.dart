// models/homework_model.dart
class Homework {
  final int id;
  final String title;
  final String description;
  final int teacherId;
  final String teacherName;
  final String? subject;
  final DateTime dueDate;
  final DateTime createdAt;
  final List<int> assignedChildIds;
  final List<HomeworkSubmission> submissions;
  final List<String> attachmentUrls;

  Homework({
    required this.id,
    required this.title,
    required this.description,
    required this.teacherId,
    required this.teacherName,
    this.subject,
    required this.dueDate,
    required this.createdAt,
    required this.assignedChildIds,
    this.submissions = const [],
    this.attachmentUrls = const [],
  });

  bool get isOverdue => DateTime.now().isAfter(dueDate);
  int get submittedCount => submissions.length;
  int get totalAssigned => assignedChildIds.length;
  double get completionRate =>
      totalAssigned == 0 ? 0 : submittedCount / totalAssigned;

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
        id: json['id'],
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        teacherId: json['teacher_id'] ?? 0,
        teacherName: json['teacher_name'] ?? '',
        subject: json['subject'],
        dueDate: DateTime.parse(json['due_date']),
        createdAt: DateTime.parse(json['created_at']),
        assignedChildIds:
            List<int>.from(json['assigned_child_ids'] as List? ?? []),
        submissions: (json['submissions'] as List? ?? [])
            .map((e) => HomeworkSubmission.fromJson(e))
            .toList(),
        attachmentUrls:
            List<String>.from(json['attachment_urls'] as List? ?? []),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'subject': subject,
        'due_date': dueDate.toIso8601String(),
        'assigned_child_ids': assignedChildIds,
      };
}

class HomeworkSubmission {
  final int id;
  final int homeworkId;
  final int childId;
  final String childName;
  final DateTime submittedAt;
  final String? fileUrl;
  final String? textAnswer;
  final int? grade;
  final String? feedback;
  final bool isLate;

  HomeworkSubmission({
    required this.id,
    required this.homeworkId,
    required this.childId,
    required this.childName,
    required this.submittedAt,
    this.fileUrl,
    this.textAnswer,
    this.grade,
    this.feedback,
    this.isLate = false,
  });

  factory HomeworkSubmission.fromJson(Map<String, dynamic> json) =>
      HomeworkSubmission(
        id: json['id'],
        homeworkId: json['homework_id'],
        childId: json['child_id'],
        childName: json['child_name'] ?? '',
        submittedAt: DateTime.parse(json['submitted_at']),
        fileUrl: json['file_url'],
        textAnswer: json['text_answer'],
        grade: json['grade'],
        feedback: json['feedback'],
        isLate: json['is_late'] ?? false,
      );
}