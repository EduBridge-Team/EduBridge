import '../institutions/institution_enrollment_history.dart';

/// Manual, local-only review of annual promotion. Never writes enrollments.
enum AnnualPromotionDecision { promoted, repeating, transferred }

class AnnualPromotionChoice {
  const AnnualPromotionChoice({
    required this.enrollmentId,
    required this.decision,
    this.targetSectionId,
  });
  final int enrollmentId;
  final AnnualPromotionDecision decision;
  final int? targetSectionId;
}

class AnnualPromotionReview {
  const AnnualPromotionReview({
    required this.history,
    required this.sourceYearId,
    required this.targetYearId,
    required this.choices,
  });
  final InstitutionEnrollmentHistory history;
  final int sourceYearId, targetYearId;
  final List<AnnualPromotionChoice> choices;

  /// All active students in the source year must receive an explicit choice.
  /// Uses the same validated school academic records and enrollment history as
  /// the existing history screen; no second roster or grade model is created.
  bool get ready {
    final years = history.academic.years;
    final source = years.where((y) => y.id == sourceYearId);
    final target = years.where((y) => y.id == targetYearId);
    if (source.length != 1 || target.length != 1 ||
        !target.single.start.isAfter(source.single.start)) return false;

    final roster = history.records.where((r) =>
        r.status == InstitutionEnrollmentStatus.active &&
        history.academic.sections.any((s) =>
            s.id == r.sectionId && s.yearId == sourceYearId)).toList();
    if (roster.isEmpty || roster.map((r) => r.childId).toSet().length != roster.length ||
        choices.length != roster.length ||
        choices.map((c) => c.enrollmentId).toSet().length != choices.length) return false;

    final destinationCounts = <int, int>{};
    for (final choice in choices) {
      final matches = roster.where((r) => r.id == choice.enrollmentId);
      if (matches.length != 1) return false;
      if (choice.decision == AnnualPromotionDecision.transferred) {
        if (choice.targetSectionId != null) return false;
        continue;
      }
      final destination = history.academic.sections.where((s) =>
          s.id == choice.targetSectionId && s.yearId == targetYearId);
      if (destination.length != 1) return false;
      final sourceSection = history.academic.sections.singleWhere((s) => s.id == matches.single.sectionId);
      if (choice.decision == AnnualPromotionDecision.repeating &&
          destination.single.gradeId != sourceSection.gradeId) return false;
      if (choice.decision == AnnualPromotionDecision.promoted &&
          destination.single.gradeId == sourceSection.gradeId) return false;
      destinationCounts.update(destination.single.id, (value) => value + 1, ifAbsent: () => 1);
    }
    // Count existing active destination seats as well as selected moves.
    for (final section in history.academic.sections.where((s) => s.yearId == targetYearId)) {
      if (section.capacity == null) continue;
      final occupied = history.records.where((r) =>
          r.sectionId == section.id && r.status == InstitutionEnrollmentStatus.active).length;
      if (occupied + (destinationCounts[section.id] ?? 0) > section.capacity!) return false;
    }
    return true;
  }
}
