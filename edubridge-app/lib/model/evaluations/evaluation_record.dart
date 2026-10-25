import '../enrollment/enrollment_models.dart';

String? _optionalText(dynamic value) {
  if (value != null && value is! String)
    throw const FormatException('Invalid evaluation text');
  return value as String?;
}

DateTime _timestamp(dynamic value) {
  if (value is! String ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}').hasMatch(value)) {
    throw const FormatException('Invalid evaluation timestamp');
  }
  final day = DateTime.tryParse(value.substring(0, 10));
  final date = DateTime.tryParse(value);
  if (day == null ||
      day.toIso8601String().substring(0, 10) != value.substring(0, 10) ||
      date == null) {
    throw const FormatException('Invalid evaluation date');
  }
  return date;
}

/// One existing evaluation record, not a synthesized IEP version or approval.
class EvaluationRecord {
  EvaluationRecord._(
    this.id,
    this.childId,
    this.createdAt,
    this.type,
    this.author,
    this.cognitive,
    this.motor,
    this.emotional,
    this.social,
    this.recommendations,
    this.plan,
    List<String> methods,
  ) : teachingMethods = List.unmodifiable(methods);
  final int id, childId;
  final DateTime createdAt;
  final String? type,
      author,
      cognitive,
      motor,
      emotional,
      social,
      recommendations,
      plan;
  final List<String> teachingMethods;
  factory EvaluationRecord.fromJson(Map<String, dynamic> data) {
    final methods = data['teaching_methods'];
    if (methods != null &&
        (methods is! List || methods.any((value) => value is! String))) {
      throw const FormatException('Invalid teaching methods');
    }
    return EvaluationRecord._(
      enrollmentId(data['id']),
      enrollmentId(data['child_id']),
      _timestamp(data['created_at']),
      _optionalText(data['evaluation_type']),
      _optionalText(data['evaluator_name']),
      _optionalText(data['cognitive_assessment']),
      _optionalText(data['motor_assessment']),
      _optionalText(data['emotional_assessment']),
      _optionalText(data['social_assessment']),
      _optionalText(data['recommendations']),
      _optionalText(data['educational_plan']),
      methods == null ? [] : List<String>.from(methods),
    );
  }
}

class EvaluationHistory {
  EvaluationHistory._(this.childId, List<EvaluationRecord> records)
    : records = List.unmodifiable(records);
  final int childId;
  final List<EvaluationRecord> records;
  factory EvaluationHistory.fromJson(int childId, Map<String, dynamic> data) {
    if (childId < 1) throw const FormatException('Invalid child');
    final records = enrollmentList(data['evaluations'])
        .map((value) => EvaluationRecord.fromJson(enrollmentMap(value)))
        .toList();
    if (records.any((value) => value.childId != childId) ||
        records.map((value) => value.id).toSet().length != records.length) {
      throw const FormatException('Evaluation child scope mismatch');
    }
    records.sort((a, b) {
      final order = b.createdAt.compareTo(a.createdAt);
      return order == 0 ? b.id.compareTo(a.id) : order;
    });
    return EvaluationHistory._(childId, records);
  }
}
