// lib/models/therapy_request_model.dart
enum TherapyRequestStatus {
  pending,    // في انتظار المختص
  scheduled,  // تم تحديد موعد
  completed,  // انتهت
  cancelled,  // ملغية
}

class TherapyRequest {
  final int id;
  final int childId;
  final String childName;
  final int parentId;
  final String parentName;
  final String reason;
  final String? description;
  final String urgency; // low | medium | high
  final TherapyRequestStatus status;
  final DateTime? scheduledAt;
  final String? meetingLink;
  final int? specialistId;
  final String? specialistName;
  final String? specialistNotes;
  final DateTime createdAt;

  TherapyRequest({
    required this.id,
    required this.childId,
    required this.childName,
    required this.parentId,
    required this.parentName,
    required this.reason,
    this.description,
    this.urgency = 'medium',
    required this.status,
    this.scheduledAt,
    this.meetingLink,
    this.specialistId,
    this.specialistName,
    this.specialistNotes,
    required this.createdAt,
  });

  factory TherapyRequest.fromJson(Map<String, dynamic> json) =>
      TherapyRequest(
        id: json['id'],
        childId: json['child_id'],
        childName: json['child_name'] ?? '',
        parentId: json['parent_id'] ?? 0,
        parentName: json['parent_name'] ?? '',
        reason: json['reason'] ?? '',
        description: json['description'],
        urgency: json['urgency'] ?? 'medium',
        status: TherapyRequestStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TherapyRequestStatus.pending,
        ),
        scheduledAt: json['scheduled_at'] != null
            ? DateTime.parse(json['scheduled_at'])
            : null,
        meetingLink: json['meeting_link'],
        specialistId: json['specialist_id'],
        specialistName: json['specialist_name'],
        specialistNotes: json['specialist_notes'],
        createdAt: DateTime.parse(json['created_at']),
      );

  // ─── مساعدات ───
  bool get isPending => status == TherapyRequestStatus.pending;
  bool get isScheduled => status == TherapyRequestStatus.scheduled;

  String get urgencyLabel {
    switch (urgency) {
      case 'high':
        return '🟠 أولوية مرتفعة';
      case 'low':
        return '🟢 أولوية مرنة';
      default:
        return '🟡 أولوية عادية';
    }
  }

  String get statusLabel {
    switch (status) {
      case TherapyRequestStatus.pending:
        return 'قيد المراجعة';
      case TherapyRequestStatus.scheduled:
        return 'تم تحديد موعد';
      case TherapyRequestStatus.completed:
        return 'مكتملة';
      case TherapyRequestStatus.cancelled:
        return 'ملغية';
    }
  }
}