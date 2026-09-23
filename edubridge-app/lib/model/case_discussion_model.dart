// lib/models/case_discussion_model.dart
// نموذج دراسة الحالة — نقاش بين المعلم والمختص بإشراف
enum CaseMessageType {
  text,        // رسالة عادية
  observation, // ملاحظة
  decision,    // قرار
  question,    // سؤال
}

enum CaseDiscussionStatus { open, inReview, resolved }

class CaseMessage {
  final int id;
  final int discussionId;
  final int senderId;
  final String senderName;
  final String senderRole; // teacher | specialist | admin
  final String content;
  final CaseMessageType type;
  final DateTime createdAt;
  final List<String> attachments;

  CaseMessage({
    required this.id,
    required this.discussionId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    this.type = CaseMessageType.text,
    required this.createdAt,
    this.attachments = const [],
  });

  factory CaseMessage.fromJson(Map<String, dynamic> json) => CaseMessage(
        id: json['id'],
        discussionId: json['discussion_id'],
        senderId: json['sender_id'] ?? 0,
        senderName: json['sender_name'] ?? '',
        senderRole: json['sender_role'] ?? '',
        content: json['content'] ?? '',
        type: CaseMessageType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CaseMessageType.text,
        ),
        createdAt: DateTime.parse(json['created_at']),
        attachments: List<String>.from(json['attachments'] as List? ?? []),
      );

  Map<String, dynamic> toJson() => {
        'content': content,
        'type': type.name,
        'attachments': attachments,
      };
}

class CaseDiscussion {
  final int id;
  final int childId;
  final String childName;
  final String childAvatar; // emoji فقط للعرض
  final String? disabilityType;
  final String topic;
  final String? description;
  final CaseDiscussionStatus status;
  final int createdById;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<CaseParticipant> participants;
  final List<CaseMessage> messages;
  final int unreadCount;

  CaseDiscussion({
    required this.id,
    required this.childId,
    required this.childName,
    this.childAvatar = '🧒',
    this.disabilityType,
    required this.topic,
    this.description,
    this.status = CaseDiscussionStatus.open,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
    this.resolvedAt,
    this.participants = const [],
    this.messages = const [],
    this.unreadCount = 0,
  });

  factory CaseDiscussion.fromJson(Map<String, dynamic> json) =>
      CaseDiscussion(
        id: json['id'],
        childId: json['child_id'],
        childName: json['child_name'] ?? '',
        childAvatar: json['child_avatar'] ?? '🧒',
        disabilityType: json['disability_type'],
        topic: json['topic'] ?? '',
        description: json['description'],
        status: CaseDiscussionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CaseDiscussionStatus.open,
        ),
        createdById: json['created_by_id'] ?? 0,
        createdByName: json['created_by_name'] ?? '',
        createdAt: DateTime.parse(json['created_at']),
        resolvedAt: json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'])
            : null,
        participants: (json['participants'] as List? ?? [])
            .map((e) => CaseParticipant.fromJson(e))
            .toList(),
        messages: (json['messages'] as List? ?? [])
            .map((e) => CaseMessage.fromJson(e))
            .toList(),
        unreadCount: json['unread_count'] ?? 0,
      );

  String get statusLabel {
    switch (status) {
      case CaseDiscussionStatus.open:
        return 'مفتوحة';
      case CaseDiscussionStatus.inReview:
        return 'قيد المراجعة';
      case CaseDiscussionStatus.resolved:
        return 'محلولة';
    }
  }
}

class CaseParticipant {
  final int userId;
  final String name;
  final String role; // teacher | specialist
  final String? specialty;

  CaseParticipant({
    required this.userId,
    required this.name,
    required this.role,
    this.specialty,
  });

  factory CaseParticipant.fromJson(Map<String, dynamic> json) =>
      CaseParticipant(
        userId: json['user_id'],
        name: json['name'] ?? '',
        role: json['role'] ?? '',
        specialty: json['specialty'],
      );

  String get emoji {
    if (role == 'teacher') return '👨‍🏫';
    if (specialty == 'learning_support') return '📘';
    if (specialty == 'educational') return '📚';
    if (specialty == 'communication_support') return '🗣️';
    if (specialty == 'learning_behavior') return '🎯';
    return '🧩';
  }
}