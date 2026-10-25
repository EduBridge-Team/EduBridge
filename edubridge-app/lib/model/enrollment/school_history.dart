import 'enrollment_models.dart';

enum SchoolRecordStatus { active, closed, transferred }

DateTime _date(dynamic value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('Invalid enrollment date');
  }
  final date = DateTime.tryParse(value);
  if (date == null || date.toIso8601String().substring(0, 10) != value) {
    throw const FormatException('Invalid calendar date');
  }
  return date;
}

class SchoolHistoryRecord {
  const SchoolHistoryRecord({
    required this.id,
    required this.childId,
    required this.schoolId,
    required this.schoolName,
    required this.sectionLabel,
    required this.status,
    required this.startedOn,
    required this.endedOn,
    required this.transferredToId,
  });
  final int id, childId, schoolId;
  final String schoolName, sectionLabel;
  final SchoolRecordStatus status;
  final DateTime startedOn;
  final DateTime? endedOn;
  final int? transferredToId;

  factory SchoolHistoryRecord.fromJson(Map<String, dynamic> data) {
    final status = SchoolRecordStatus.values.where((s) => s.name == data['status']);
    if (status.length != 1 || !data.containsKey('ended_on') ||
        !data.containsKey('transferred_to_enrollment_id')) {
      throw const FormatException('Missing record state');
    }
    final start = _date(data['started_on']);
    final end = data['ended_on'] == null ? null : _date(data['ended_on']);
    final target = data['transferred_to_enrollment_id'] == null
        ? null : enrollmentId(data['transferred_to_enrollment_id']);
    if ((status.single == SchoolRecordStatus.active) != (end == null) ||
        (end != null && end.isBefore(start)) ||
        (status.single == SchoolRecordStatus.transferred) != (target != null)) {
      throw const FormatException('Inconsistent record state');
    }
    return SchoolHistoryRecord(
      id: enrollmentId(data['id']),
      childId: enrollmentId(data['child_id']),
      schoolId: enrollmentId(data['school_id']),
      schoolName: enrollmentText(data['school_name']),
      sectionLabel: enrollmentText(data['section_label']),
      status: status.single,
      startedOn: start,
      endedOn: end,
      transferredToId: target,
    );
  }
}

class SchoolHistory {
  SchoolHistory._(List<SchoolHistoryRecord> records)
      : records = List.unmodifiable(records);
  final List<SchoolHistoryRecord> records;

  factory SchoolHistory.fromJson(Map<String, dynamic> data, int childId) {
    if (enrollmentId(data['child_id']) != enrollmentId(childId)) {
      throw const FormatException('Foreign child history');
    }
    final records = enrollmentList(data['enrollments'])
        .map((v) => SchoolHistoryRecord.fromJson(enrollmentMap(v))).toList();
    final byId = {for (final record in records) record.id: record};
    if (byId.length != records.length ||
        records.any((r) => r.childId != childId) ||
        records.where((r) => r.status == SchoolRecordStatus.active).length > 1) {
      throw const FormatException('Invalid enrollment scope');
    }
    for (final record in records) {
      if (record.transferredToId == null) continue;
      final target = byId[record.transferredToId];
      if (target == null || target.id == record.id ||
          target.schoolId == record.schoolId ||
          target.startedOn.isBefore(record.endedOn!)) {
        throw const FormatException('Invalid transfer link');
      }
      final visited = <int>{record.id};
      SchoolHistoryRecord? next = target;
      while (next != null) {
        if (!visited.add(next.id)) throw const FormatException('Transfer cycle');
        next = byId[next.transferredToId];
      }
    }
    records.sort((a, b) {
      final order = b.startedOn.compareTo(a.startedOn);
      return order == 0 ? b.id.compareTo(a.id) : order;
    });
    return SchoolHistory._(records);
  }
}
