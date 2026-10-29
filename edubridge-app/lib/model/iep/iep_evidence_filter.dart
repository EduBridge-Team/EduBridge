import 'iep_goal_evidence.dart';

enum IepEvidenceKind { all, numeric, qualitative }
List<IepGoalEvidence> filterIepEvidence(IepEvidenceHistory history, IepEvidenceKind kind,
    String query, bool oldestFirst) {
  final search = query.trim().toLowerCase();
  final filtered = history.entries.where((entry) {
    if (kind == IepEvidenceKind.numeric && entry.measurement == null) return false;
    if (kind == IepEvidenceKind.qualitative && entry.measurement != null) return false;
    return [entry.observation, entry.sourceLabel, entry.author ?? '']
        .any((text) => text.toLowerCase().contains(search));
  }).toList();
  return List.unmodifiable(oldestFirst ? filtered.reversed : filtered);
}
