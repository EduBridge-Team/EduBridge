import '../enrollment/enrollment_models.dart';
import 'iep_fields.dart';
import 'iep_goal.dart';

/// Identifies one goal in one student's immutable plan version.
class IepEvidenceSource {
  const IepEvidenceSource({required this.childId, required this.planId, required this.goal});
  final int childId, planId;
  final IepGoal goal;
}

class IepGoalEvidence {
  const IepGoalEvidence._(this.id, this.sourceLabel, this.observation,
      this.observedOn, this.recordedAt, this.measurement, this.author);
  final int id;
  final String sourceLabel, observation;
  final DateTime observedOn, recordedAt;
  final num? measurement;
  final String? author;

  factory IepGoalEvidence.fromJson(Map<String, dynamic> data, String unit) {
    final timestamp = data['recorded_at'];
    if (timestamp is! String || !RegExp(
      r'^\d{4}-\d{2}-\d{2}T(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d+)?(?:Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)$',
    ).hasMatch(timestamp)) {
      throw const FormatException('Evidence requires an unambiguous timestamp');
    }
    final value = data['measurement'];
    if ((value == null) != (data['unit'] == null) ||
        (value != null && data['unit'] != unit)) {
      throw const FormatException('Evidence unit mismatch');
    }
    return IepGoalEvidence._(
      enrollmentId(data['id']),
      enrollmentText(data['source_label']),
      enrollmentText(data['observation']),
      iepDate(data['observed_on']),
      iepTimestamp(timestamp),
      value == null ? null : iepMeasurement(value),
      iepOptionalText(data['author_name']),
    );
  }
}

/// A complete authorized history, never a computed goal-achievement score.
class IepEvidenceHistory {
  IepEvidenceHistory._(this.source, this.revision, List<IepGoalEvidence> entries)
      : entries = List.unmodifiable(entries);
  final IepEvidenceSource source;
  final String revision;
  final List<IepGoalEvidence> entries;

  factory IepEvidenceHistory.fromJson(IepEvidenceSource source, Map<String, dynamic> data) {
    if (data['contract_version'] != 1 || data['complete'] != true ||
        enrollmentId(data['child_id']) != source.childId ||
        enrollmentId(data['plan_id']) != source.planId ||
        enrollmentId(data['plan_version_id']) != source.goal.versionId ||
        enrollmentId(data['goal_id']) != source.goal.id ||
        data['unit'] != source.goal.unit) {
      throw const FormatException('Invalid evidence history scope');
    }
    final entries = enrollmentList(data['evidence']).map((item) =>
      IepGoalEvidence.fromJson(enrollmentMap(item), source.goal.unit)).toList();
    if (entries.map((e) => e.id).toSet().length != entries.length) {
      throw const FormatException('Duplicate evidence');
    }
    entries.sort((a, b) {
      final date = b.observedOn.compareTo(a.observedOn);
      if (date != 0) return date;
      final recorded = b.recordedAt.compareTo(a.recordedAt);
      return recorded != 0 ? recorded : b.id.compareTo(a.id);
    });
    return IepEvidenceHistory._(source, enrollmentText(data['revision']), entries);
  }

  bool matches(IepEvidenceSource other) =>
      source.childId == other.childId && source.planId == other.planId &&
      source.goal.id == other.goal.id && source.goal.versionId == other.goal.versionId &&
      source.goal.unit == other.goal.unit;
}

