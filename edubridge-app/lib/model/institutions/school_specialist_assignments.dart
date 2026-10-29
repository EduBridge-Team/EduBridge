import '../enrollment/enrollment_models.dart';
import '../iep/iep_fields.dart';

class SchoolSpecialistAssignment {
  const SchoolSpecialistAssignment._(this.id, this.specialistId, this.name,
      this.startsOn, this.endedOn, this.canEnd);
  final int id, specialistId;
  final String name;
  final DateTime startsOn;
  final DateTime? endedOn;
  final bool canEnd;
  bool get active => endedOn == null;
  factory SchoolSpecialistAssignment.fromJson(Map<String, dynamic> data) {
    final start = iepDate(data['starts_on']);
    final end = data['ended_on'] == null ? null : iepDate(data['ended_on']);
    if (!data.containsKey('ended_on') || data['can_end'] is! bool ||
        (end != null && (end.isBefore(start) || data['can_end'] == true))) {
      throw const FormatException('Invalid specialist assignment state');
    }
    return SchoolSpecialistAssignment._(enrollmentId(data['id']),
      enrollmentId(data['specialist_id']), enrollmentText(data['specialist_name']),
      start, end, data['can_end'] as bool);
  }
}

class SchoolSpecialistAssignments {
  SchoolSpecialistAssignments._(this.organizationId, this.schoolId, this.schoolName, this.revision,
      this.effectiveOn, this.canAssign, Map<int, String> eligible,
      List<SchoolSpecialistAssignment> assignments)
      : eligible = Map.unmodifiable(eligible), assignments = List.unmodifiable(assignments);
  final int organizationId, schoolId;
  final String revision, schoolName;
  final DateTime effectiveOn;
  final bool canAssign;
  final Map<int, String> eligible;
  final List<SchoolSpecialistAssignment> assignments;
  bool canAdd(int specialistId) => canAssign && eligible.containsKey(specialistId) &&
      !assignments.any((a) => a.active && a.specialistId == specialistId);
  factory SchoolSpecialistAssignments.fromJson(int organizationId, int schoolId, Map<String, dynamic> data) {
    final capabilities = enrollmentMap(data['capabilities']);
    if (data['contract_version'] != 1 || data['complete'] != true ||
        enrollmentId(data['organization_id']) != organizationId ||
        enrollmentId(data['school_id']) != schoolId || capabilities['can_assign'] is! bool) {
      throw const FormatException('Invalid specialist school scope');
    }
    final effective = iepDate(data['effective_on']);
    final eligible = <int, String>{};
    for (final item in enrollmentList(data['eligible_specialists'])) {
      final row = enrollmentMap(item), id = enrollmentId(enrollmentMap(item)['id']);
      if (eligible.containsKey(id)) throw const FormatException('Duplicate specialist');
      eligible[id] = enrollmentText(row['name']);
    }
    final assignments = enrollmentList(data['assignments']).map((a) =>
      SchoolSpecialistAssignment.fromJson(enrollmentMap(a))).toList();
    final active = assignments.where((a) => a.active).toList();
    if (assignments.map((a) => a.id).toSet().length != assignments.length ||
        active.map((a) => a.specialistId).toSet().length != active.length ||
        assignments.any((a) => a.startsOn.isAfter(effective) || (a.endedOn?.isAfter(effective) ?? false))) {
      throw const FormatException('Invalid specialist history');
    }
    assignments.sort((a, b) => b.id.compareTo(a.id));
    return SchoolSpecialistAssignments._(organizationId, schoolId, enrollmentText(data['school_name']),
      enrollmentText(data['revision']), effective, capabilities['can_assign'] as bool,
      eligible, assignments);
  }
}

