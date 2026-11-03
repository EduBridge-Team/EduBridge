/// Loaded lesson records retain every API field used by media and lesson cards.
class ChildLessonsResult {
  const ChildLessonsResult({
    this.lessons = const [],
    this.doneLessonIds = const {},
    this.progressAvailable = false,
    this.error,
  });

  final List<dynamic> lessons;
  final Set<int> doneLessonIds;
  /// True only for an explicit successful progress list, including an empty list.
  final bool progressAvailable;
  final String? error;
}
