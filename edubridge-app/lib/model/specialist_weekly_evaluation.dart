/// Read the labelled sections written by the existing weekly-report API.
/// Older free-text evaluations remain visible as notes.
class SpecialistWeeklyEvaluation {
  final String notes;
  final String recommendations;
  final String? suitability;
  final String planChanges;
  final String? interaction;

  const SpecialistWeeklyEvaluation({
    required this.notes,
    required this.recommendations,
    required this.suitability,
    required this.planChanges,
    required this.interaction,
  });

  factory SpecialistWeeklyEvaluation.fromNotes(String? value) {
    const labels = ['التوصيات', 'ملاءمة الخطة', 'تقييم الخطة', 'تقييم التفاعل'];
    final sections = <String, List<String>>{'notes': []};
    var section = 'notes';
    for (final line in (value ?? '').split('\n')) {
      final trimmed = line.trim();
      final label = labels.where((label) => trimmed.startsWith('$label:')).firstOrNull;
      if (label != null) {
        section = label;
        sections.putIfAbsent(section, () => []).add(trimmed.substring(label.length + 1).trim());
      } else {
        sections.putIfAbsent(section, () => []).add(line);
      }
    }
    String read(String name) => (sections[name] ?? []).join('\n').trim();
    return SpecialistWeeklyEvaluation(
      notes: read('notes'), recommendations: read('التوصيات'),
      suitability: read('ملاءمة الخطة').isEmpty ? null : read('ملاءمة الخطة'),
      planChanges: read('تقييم الخطة'),
      interaction: read('تقييم التفاعل').isEmpty ? null : read('تقييم التفاعل'),
    );
  }
}
