/// Unsaved authoring values. These are never an approved or server-saved plan.
class IepDraftGoal {
  IepDraftGoal({
    required String title,
    required this.baseline,
    required this.target,
    required String unit,
    required String method,
    required this.start,
    required this.end,
    String responsible = '',
  }) : title = title.trim(),
       unit = unit.trim(),
       method = method.trim(),
       responsible = responsible.trim() {
    if (this.title.isEmpty ||
        this.unit.isEmpty ||
        this.method.isEmpty ||
        !baseline.isFinite ||
        !target.isFinite ||
        !end.isAfter(start)) {
      throw const FormatException('Invalid draft goal');
    }
  }
  final String title, unit, method, responsible;
  final num baseline, target;
  final DateTime start, end;
}

class IepPlanDraft {
  IepPlanDraft({
    required this.childId,
    required this.evaluationId,
    required String title,
    required this.start,
    required this.end,
    required this.reviewOn,
    required List<IepDraftGoal> goals,
    String summary = '',
    List<String> accommodations = const [],
  }) : title = title.trim(),
       summary = summary.trim(),
       goals = List.unmodifiable(goals),
       accommodations = List.unmodifiable(accommodations.map((s) => s.trim())) {
    if (childId < 1 ||
        evaluationId < 1 ||
        this.title.isEmpty ||
        !end.isAfter(start) ||
        reviewOn.isBefore(start) ||
        goals.isEmpty ||
        goals.any((g) => g.start.isBefore(start) || g.end.isAfter(end)) ||
        this.accommodations.any((s) => s.isEmpty)) {
      throw const FormatException('Invalid plan draft');
    }
  }
  final int childId, evaluationId;
  final String title, summary;
  final DateTime start, end, reviewOn;
  final List<IepDraftGoal> goals;
  final List<String> accommodations;
}

String normalizeIepNumerals(String value) =>
    value.trim().replaceAllMapped(RegExp('[٠-٩۰-۹]'), (match) {
      final code = match[0]!.codeUnitAt(0);
      return (code - (code >= 0x6f0 ? 0x6f0 : 0x660)).toString();
    });

/// Accept decimal values (including decreasing targets), never exponents/NaN.
num? parseIepMeasurement(String value) {
  final text = normalizeIepNumerals(value).replaceAll('٫', '.');
  if (!RegExp(r'^-?[0-9]+(?:\.[0-9]+)?$').hasMatch(text)) return null;
  final number = num.tryParse(text);
  return number != null && number.isFinite ? number : null;
}

DateTime? parseIepDraftDate(String value) {
  final text = normalizeIepNumerals(value);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return null;
  final date = DateTime.tryParse(text);
  return date != null && date.toIso8601String().substring(0, 10) == text
      ? date
      : null;
}
