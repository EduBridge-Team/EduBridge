import '../enrollment/enrollment_models.dart';

class MinistryStatistics {
  MinistryStatistics._(Map<String, num?> metrics, this.disabilities, this.ages)
      : metrics = Map.unmodifiable(metrics);
  final Map<String, num?> metrics;
  final Map<String, int>? disabilities, ages;
  factory MinistryStatistics.fromJson(Map<String, dynamic> data) {
    if (data['success'] == false || data['error'] != null || data.isEmpty) {
      throw const FormatException('Invalid ministry statistics');
    }
    final metrics = <String, num?>{};
    for (final key in [
      'total_children',
      'active_children',
      'learning_support_meetings_count',
      'homework_completion_rate'
    ]) {
      final value = data[key];
      if (value != null &&
          (value is! num ||
              !value.isFinite ||
              value < 0 ||
              (key == 'homework_completion_rate'
                  ? value > 100
                  : value is! int))) {
        throw const FormatException('Invalid ministry metric');
      }
      metrics[key] = value as num?;
    }
    if (metrics['total_children'] != null &&
        metrics['active_children'] != null &&
        metrics['active_children']! > metrics['total_children']!) {
      throw const FormatException('Active count exceeds total');
    }
    Map<String, int>? distribution(dynamic raw) {
      if (raw == null) return null;
      if (raw is List && raw.isEmpty) return const {};
      if (raw is! Map || raw.keys.any((key) => key is! String)) {
        throw const FormatException('Invalid distribution');
      }
      final values = Map<String, dynamic>.from(raw);
      return Map.unmodifiable(values.map((key, value) {
        enrollmentText(key);
        if (value is! int || value < 0)
          throw const FormatException('Invalid distribution');
        return MapEntry(key, value);
      }));
    }

    if (!metrics.values.any((value) => value != null) &&
        !data.containsKey('by_disability_type') &&
        !data.containsKey('by_age_group')) {
      throw const FormatException('No statistics fields');
    }
    return MinistryStatistics._(
        metrics,
        distribution(data['by_disability_type']),
        distribution(data['by_age_group']));
  }
}
