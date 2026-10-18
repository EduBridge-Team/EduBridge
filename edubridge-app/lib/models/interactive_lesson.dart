/// Domain-only representation of the versioned interactive lesson catalog.
///
/// This is deliberately independent from networking and widget code.
/// Templates are never published to learners automatically.
class InteractiveLessonCatalog {
  const InteractiveLessonCatalog({
    required this.schemaVersion,
    required this.locale,
    required this.templates,
  });

  final String schemaVersion;
  final String locale;
  final List<InteractiveLesson> templates;

  factory InteractiveLessonCatalog.fromJson(Map<String, dynamic> json) {
    final raw = _requiredList(json, 'templates');
    final lessons = raw.map((value) {
      return InteractiveLesson.fromJson(_asMap(value, 'template'));
    }).toList(growable: false);
    _unique(lessons.map((lesson) => lesson.id), 'lesson ID');
    return InteractiveLessonCatalog(
      schemaVersion: _requiredString(json, 'schema_version'),
      locale: _requiredString(json, 'locale'),
      templates: List.unmodifiable(lessons),
    );
  }
}

class InteractiveLesson {
  const InteractiveLesson({
    required this.id,
    required this.subject,
    required this.title,
    required this.objective,
    required this.steps,
  });

  final String id;
  final String subject;
  final String title;
  final String objective;
  final List<InteractiveLessonStep> steps;

  factory InteractiveLesson.fromJson(Map<String, dynamic> json) {
    final steps = _requiredList(json, 'steps')
        .map((value) => InteractiveLessonStep.fromJson(_asMap(value, 'step')))
        .toList(growable: false);
    if (steps.isEmpty) {
      throw const FormatException('A lesson requires at least one step');
    }
    _unique(steps.map((step) => step.id), 'step ID');
    return InteractiveLesson(
      id: _requiredString(json, 'id'),
      subject: _requiredString(json, 'subject'),
      title: _requiredString(json, 'title'),
      objective: _requiredString(json, 'objective'),
      steps: List.unmodifiable(steps),
    );
  }
}

sealed class InteractiveLessonStep {
  const InteractiveLessonStep(this.id);
  final String id;

  factory InteractiveLessonStep.fromJson(Map<String, dynamic> json) {
    final id = _requiredString(json, 'id');
    switch (_requiredString(json, 'type')) {
      case 'explanation':
        return LessonExplanation(id, _requiredString(json, 'text'));
      case 'single_choice':
        final options = _requiredList(json, 'options')
            .map((value) => LessonOption.fromJson(_asMap(value, 'option')))
            .toList(growable: false);
        if (options.length < 2) {
          throw const FormatException('A question needs at least two options');
        }
        _unique(options.map((option) => option.id), 'option ID');
        final correctId = _requiredString(json, 'correct_option_id');
        if (!options.any((option) => option.id == correctId)) {
          throw FormatException('Unknown correct option: $correctId');
        }
        return LessonSingleChoice(
          id,
          _requiredString(json, 'prompt'),
          List.unmodifiable(options),
          correctId,
        );
      default:
        throw FormatException('Unsupported step type: ${json['type']}');
    }
  }
}

class LessonExplanation extends InteractiveLessonStep {
  const LessonExplanation(super.id, this.text);
  final String text;
}

class LessonOption {
  const LessonOption(this.id, this.text);
  final String id;
  final String text;

  factory LessonOption.fromJson(Map<String, dynamic> json) =>
      LessonOption(_requiredString(json, 'id'), _requiredString(json, 'text'));
}

class LessonSingleChoice extends InteractiveLessonStep {
  const LessonSingleChoice(
    super.id,
    this.prompt,
    this.options,
    this.correctOptionId,
  );

  final String prompt;
  final List<LessonOption> options;
  final String correctOptionId;

  /// For local practice only. Never trust client-side scoring for graded exams.
  bool isCorrect(String selectedOptionId) =>
      options.any((option) => option.id == selectedOptionId) &&
      selectedOptionId == correctOptionId;
}

Map<String, dynamic> _asMap(Object? value, String name) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('$name must be an object');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('$key must be a non-empty string');
}

List<dynamic> _requiredList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List) return value;
  throw FormatException('$key must be a list');
}

void _unique(Iterable<String> ids, String label) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) throw FormatException('Duplicate $label: $id');
  }
}
