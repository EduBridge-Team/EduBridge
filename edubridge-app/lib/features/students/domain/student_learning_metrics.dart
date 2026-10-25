/// Counts only lessons visible to this child; unavailable metrics stay unknown.
class StudentLearningMetrics {
  const StudentLearningMetrics({this.lessonsCount, this.completionPercent});

  final int? lessonsCount;
  final int? completionPercent;

  factory StudentLearningMetrics.fromData({
    required Object? lessons,
    required Object? progress,
  }) {
    if (lessons is! List) return const StudentLearningMetrics();
    if (lessons.isEmpty || progress is! List) {
      return StudentLearningMetrics(lessonsCount: lessons.length);
    }
    final completedIds = <int>{};
    for (final entry in progress) {
      if (entry is Map && entry['status'] == 'done') {
        final id = int.tryParse((entry['lesson_id'] ?? '').toString());
        if (id != null) completedIds.add(id);
      }
    }
    final completedVisible = lessons.where((lesson) {
      if (lesson is! Map) return false;
      final id = int.tryParse((lesson['id'] ?? '').toString());
      return id != null && completedIds.contains(id);
    }).length;
    return StudentLearningMetrics(
      lessonsCount: lessons.length,
      completionPercent: (100 * completedVisible / lessons.length).round(),
    );
  }
}
