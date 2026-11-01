import '../enrollment/enrollment_models.dart';

enum PromotionOutcome { promoted, repeating, transferred }

class PromotionStudent {
  const PromotionStudent(
    this.enrollmentId,
    this.childId,
    this.name,
    this.gradeId,
    this.sectionId, {
    this.gradePosition,
  });
  final int enrollmentId, childId, gradeId, sectionId;
  final int? gradePosition;
  final String name;
}

class PromotionDestination {
  const PromotionDestination(
    this.id,
    this.gradeId,
    this.name,
    this.capacity,
    this.occupied, {
    this.gradePosition,
  });
  final int id, gradeId, occupied;
  final int? gradePosition;
  final int? capacity;
  final String name;

  bool accepts(PromotionStudent student, PromotionOutcome outcome) {
    if (gradePosition == null || student.gradePosition == null) return false;
    return switch (outcome) {
      PromotionOutcome.promoted =>
        gradeId != student.gradeId &&
            gradePosition == student.gradePosition! + 1,
      PromotionOutcome.repeating =>
        gradeId == student.gradeId && gradePosition == student.gradePosition,
      PromotionOutcome.transferred => false,
    };
  }
}

/// Strict server-provided roster, never constructed from fake production data.
class PromotionRoster {
  PromotionRoster._(
    this.schoolId,
    this.sourceYearId,
    this.targetYearId,
    this.revision,
    List<PromotionStudent> students,
    List<PromotionDestination> sections,
  ) : students = List.unmodifiable(students),
      sections = List.unmodifiable(sections);
  final int schoolId, sourceYearId, targetYearId;
  final String revision;
  final List<PromotionStudent> students;
  final List<PromotionDestination> sections;

  factory PromotionRoster.fromJson(
    Map<String, dynamic> json, {
    required int schoolId,
    required int sourceYearId,
    required int targetYearId,
  }) {
    if (enrollmentId(json['school_id']) != schoolId ||
        enrollmentId(json['source_year_id']) != sourceYearId ||
        enrollmentId(json['target_year_id']) != targetYearId ||
        json['complete'] != true) {
      throw const FormatException('Invalid or incomplete promotion roster');
    }
    final revision = enrollmentText(json['revision']);
    final students = enrollmentList(json['students']).map((entry) {
      final v = enrollmentMap(entry);
      return PromotionStudent(
        enrollmentId(v['enrollment_id']),
        enrollmentId(v['child_id']),
        enrollmentText(v['child_name']),
        enrollmentId(v['source_grade_id']),
        enrollmentId(v['source_section_id']),
        gradePosition: enrollmentId(v['source_grade_position']),
      );
    }).toList();
    final sections = enrollmentList(json['target_sections']).map((entry) {
      final v = enrollmentMap(entry);
      final capacity = v['capacity'];
      final occupied = v['occupied'];
      if ((capacity != null && (capacity is! int || capacity < 0)) ||
          occupied is! int ||
          occupied < 0 ||
          (capacity != null && occupied > capacity)) {
        throw const FormatException('Invalid promotion capacity');
      }
      return PromotionDestination(
        enrollmentId(v['id']),
        enrollmentId(v['grade_id']),
        enrollmentText(v['name']),
        capacity as int?,
        occupied,
        gradePosition: enrollmentId(v['grade_position']),
      );
    }).toList();
    if (students.map((e) => e.enrollmentId).toSet().length != students.length ||
        students.map((e) => e.childId).toSet().length != students.length ||
        sections.map((e) => e.id).toSet().length != sections.length) {
      throw const FormatException('Duplicated promotion records');
    }
    return PromotionRoster._(
      schoolId,
      sourceYearId,
      targetYearId,
      revision,
      students,
      sections,
    );
  }
}

class PromotionSelection {
  const PromotionSelection(
    this.enrollmentId,
    this.outcome,
    this.targetSectionId, {
    this.targetSchoolId,
  });
  final int enrollmentId;
  final PromotionOutcome outcome;
  final int? targetSectionId, targetSchoolId;
  Map<String, dynamic> toJson() => {
    'enrollment_id': enrollmentId,
    'decision': outcome.name,
    if (targetSectionId != null) 'target_section_id': targetSectionId,
    if (targetSchoolId != null) 'target_school_id': targetSchoolId,
  };
}

/// A local preview is not a server approval; its validation is only advisory.
class PromotionDraft {
  PromotionDraft(this.roster, Map<int, PromotionSelection> selections)
    : selections = Map.unmodifiable(selections);
  final PromotionRoster roster;
  final Map<int, PromotionSelection> selections;

  bool get ready {
    if (roster.students.isEmpty || selections.length != roster.students.length)
      return false;
    final planned = <int, int>{};
    for (final student in roster.students) {
      final selection = selections[student.enrollmentId];
      if (selection == null || selection.enrollmentId != student.enrollmentId)
        return false;
      if (selection.outcome == PromotionOutcome.transferred) {
        if (selection.targetSectionId != null ||
            (selection.targetSchoolId ?? 0) <= 0 ||
            selection.targetSchoolId == roster.schoolId)
          return false;
        continue;
      }
      if (selection.targetSchoolId != null) return false;
      final destinations = roster.sections.where(
        (s) => s.id == selection.targetSectionId,
      );
      if (destinations.length != 1) return false;
      final destination = destinations.single;
      if (!destination.accepts(student, selection.outcome)) return false;
      planned.update(destination.id, (count) => count + 1, ifAbsent: () => 1);
    }
    for (final destination in roster.sections) {
      if (destination.capacity != null &&
          destination.occupied + (planned[destination.id] ?? 0) >
              destination.capacity!) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> previewJson() {
    if (!ready) throw StateError('Incomplete promotion choices');
    return {
      'source_year_id': roster.sourceYearId,
      'target_year_id': roster.targetYearId,
      'roster_revision': roster.revision,
      'decisions': [
        for (final student in roster.students)
          selections[student.enrollmentId]!.toJson(),
      ],
    };
  }
}
