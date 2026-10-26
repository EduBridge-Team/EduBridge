import '../enrollment/enrollment_models.dart';
import 'iep_fields.dart';
import 'iep_goal.dart';

enum IepVersionStatus { draft, submitted, returned, approved }

class IepReviewComment {
  IepReviewComment._(
    this.id,
    this.versionId,
    this.text,
    this.author,
    this.createdAt,
  );
  final int id, versionId;
  final String text;
  final String? author;
  final DateTime createdAt;
  factory IepReviewComment.fromJson(Map<String, dynamic> data) =>
      IepReviewComment._(
        enrollmentId(data['id']),
        enrollmentId(data['plan_version_id']),
        enrollmentText(data['text']),
        iepOptionalText(data['author_name']),
        iepTimestamp(data['created_at']),
      );
}

class IepVersion {
  IepVersion._(
    this.id,
    this.planId,
    this.childId,
    this.number,
    this.evaluationId,
    this.status,
    this.summary,
    this.author,
    this.returnReason,
    this.createdAt,
    this.start,
    this.end,
    this.reviewOn,
    this.goals,
    this.accommodations,
    this.comments,
  );
  final int id, planId, childId, number, evaluationId;
  final IepVersionStatus status;
  final String? summary, author, returnReason;
  final DateTime createdAt, start, end, reviewOn;
  final List<IepGoal> goals;
  final List<String> accommodations;
  final List<IepReviewComment> comments;
  factory IepVersion.fromJson(Map<String, dynamic> data) {
    final id = enrollmentId(data['id']);
    final status = switch (data['status']) {
      'draft' => IepVersionStatus.draft,
      'submitted' => IepVersionStatus.submitted,
      'returned' => IepVersionStatus.returned,
      'approved' => IepVersionStatus.approved,
      _ => throw const FormatException('Unknown IEP status'),
    };
    final start = iepDate(data['starts_on']), end = iepDate(data['ends_on']);
    final reason = iepOptionalText(data['return_reason']);
    final goals = enrollmentList(data['goals'])
        .map((v) => IepGoal.fromJson(enrollmentMap(v)))
        .toList();
    final comments = enrollmentList(data['review_comments'])
        .map((v) => IepReviewComment.fromJson(enrollmentMap(v)))
        .toList();
    if (!end.isAfter(start) ||
        (status == IepVersionStatus.returned &&
            (reason == null || reason.trim().isEmpty)) ||
        goals.map((v) => v.id).toSet().length != goals.length ||
        comments.map((v) => v.id).toSet().length != comments.length ||
        comments.any((v) => v.versionId != id) ||
        goals.any(
          (v) =>
              v.versionId != id ||
              v.start.isBefore(start) ||
              v.end.isAfter(end),
        )) {
      throw const FormatException('Invalid IEP version relations');
    }
    comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return IepVersion._(
      id,
      enrollmentId(data['plan_id']),
      enrollmentId(data['child_id']),
      enrollmentId(data['version_number']),
      enrollmentId(data['evaluation_id']),
      status,
      iepOptionalText(data['summary']),
      iepOptionalText(data['created_by_name']),
      reason,
      iepTimestamp(data['created_at']),
      start,
      end,
      iepDate(data['review_on']),
      List.unmodifiable(goals),
      iepTexts(data['accommodations']),
      List.unmodifiable(comments),
    );
  }
}
