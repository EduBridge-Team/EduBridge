import 'academic_catalog.dart';
import 'curriculum_catalog.dart';

enum CurriculumKind { term, subject }

class CurriculumDraft {
  const CurriculumDraft({
    required this.kind,
    required this.name,
    this.yearId,
    this.position,
    this.start,
    this.end,
    this.code,
    this.active = true,
  });
  final CurriculumKind kind;
  final String name;
  final int? yearId, position;
  final DateTime? start, end;
  final String? code;
  final bool active;
  String? get normalizedCode =>
      code == null || code!.trim().isEmpty ? null : code!.trim();
  bool get valid {
    if (name.trim().isEmpty ||
        name.trim().length > (kind == CurriculumKind.term ? 60 : 120))
      return false;
    if (kind == CurriculumKind.subject)
      return (normalizedCode?.length ?? 0) <= 40;
    if ((yearId ?? 0) < 1 ||
        (position ?? 0) < 1 ||
        position! > 20 ||
        start == null ||
        end == null)
      return false;
    return academicDate(academicDateText(end!))
        .isAfter(academicDate(academicDateText(start!)));
  }

  bool validFor(CurriculumCatalog catalog) {
    if (!valid) return false;
    if (kind == CurriculumKind.subject) return true;
    final years = catalog.years.where((year) => year.id == yearId);
    if (years.isEmpty) return false;
    final year = years.single;
    return !academicDate(academicDateText(start!)).isBefore(year.start) &&
        !academicDate(academicDateText(end!)).isAfter(year.end) &&
        !catalog.terms.any(
          (term) => term.yearId == yearId && term.position == position,
        );
  }

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    if (kind == CurriculumKind.term) ...{
      'academic_year_id': yearId,
      'position': position,
      'starts_on': academicDateText(start!),
      'ends_on': academicDateText(end!),
    } else ...{
      'code': normalizedCode,
      'is_active': active,
    },
  };
}
