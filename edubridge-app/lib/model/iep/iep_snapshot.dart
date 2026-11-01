import 'dart:convert';
import 'iep_plan_history.dart';
import 'iep_version.dart';

/// JSON integer/decimal representations compare by exact numeric value.
/// Convert only integral doubles representable by Dart's signed integer range.
String iepSnapshotFingerprint(Object? value) => jsonEncode(_canonical(value));

Object? _canonical(Object? value) {
  if (value is double &&
      value >= -9223372036854775808.0 &&
      value < 9223372036854775808.0 &&
      value == value.truncateToDouble()) {
    return value.toInt();
  }
  if (value is Map<String, dynamic>) {
    return value.map((key, item) => MapEntry(key, _canonical(item)));
  }
  if (value is List) return value.map(_canonical).toList();
  return value;
}

/// Authored and audit fields used to confirm server-owned IEP history.
Map<String, Object?> iepVersionContent(IepVersion v) => {
      'id': v.id,
      'plan': v.planId,
      'child': v.childId,
      'number': v.number,
      'evaluation': v.evaluationId,
      'summary': v.summary,
      'author': v.author,
      'created': v.createdAt.toIso8601String(),
      'start': v.start.toIso8601String(),
      'end': v.end.toIso8601String(),
      'review': v.reviewOn.toIso8601String(),
      'accommodations': v.accommodations,
      'goals': [
        for (final g in v.goals)
          [
            g.id,
            g.versionId,
            g.title,
            g.baseline,
            g.target,
            g.unit,
            g.method,
            g.responsible,
            g.start.toIso8601String(),
            g.end.toIso8601String()
          ]
      ],
    };

Map<String, Object?> iepVersionSnapshot(IepVersion v) => {
      ...iepVersionContent(v),
      'status': v.status.name,
      'reason': v.returnReason,
      'comments': [
        for (final c in v.comments)
          [c.id, c.versionId, c.text, c.author, c.createdAt.toIso8601String()]
      ],
    };

Map<String, Object?> iepPlanSnapshot(IepPlan p) => {
      'plan': p.id,
      'child': p.childId,
      'title': p.title,
      'closed': p.closed,
      'approved': p.currentApprovedId,
      'versions': [for (final v in p.versions) iepVersionSnapshot(v)],
    };
