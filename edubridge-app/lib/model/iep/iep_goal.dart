import '../enrollment/enrollment_models.dart';
import 'iep_fields.dart';

class IepGoal {
  IepGoal._(
    this.id,
    this.versionId,
    this.title,
    this.baseline,
    this.target,
    this.unit,
    this.method,
    this.responsible,
    this.start,
    this.end,
  );
  final int id, versionId;
  final String title, unit, method;
  final String? responsible;
  final num baseline, target;
  final DateTime start, end;
  factory IepGoal.fromJson(Map<String, dynamic> data) {
    final start = iepDate(data['starts_on']), end = iepDate(data['ends_on']);
    if (!end.isAfter(start)) throw const FormatException('Invalid goal range');
    return IepGoal._(
      enrollmentId(data['id']),
      enrollmentId(data['plan_version_id']),
      enrollmentText(data['title']),
      iepMeasurement(data['baseline']),
      iepMeasurement(data['target']),
      enrollmentText(data['unit']),
      enrollmentText(data['measurement_method']),
      iepOptionalText(data['responsible_name']),
      start,
      end,
    );
  }
}
