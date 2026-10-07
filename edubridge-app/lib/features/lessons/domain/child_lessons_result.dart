/// Loaded lesson records retain every API field used by media and lesson cards.
class ChildLessonsResult {
  const ChildLessonsResult({
    this.lessons = const [],
    this.doneLessonIds = const {},
    this.error,
  });

  final List<dynamic> lessons;
  final Set<int> doneLessonIds;
  final String? error;
}
