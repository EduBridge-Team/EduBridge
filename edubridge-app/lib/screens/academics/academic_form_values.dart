/// Accept the numeral sets used by Arabic and English numeric keyboards.
int? parseAcademicCapacity(String text) => parseAcademicInteger(text);

int? parseAcademicInteger(String text) {
  final normalized = text.trim().replaceAllMapped(RegExp('[٠-٩۰-۹]'), (match) {
    final code = match[0]!.codeUnitAt(0);
    return (code - (code >= 0x6f0 ? 0x6f0 : 0x660)).toString();
  });
  return RegExp(r'^[0-9]+$').hasMatch(normalized)
      ? int.tryParse(normalized)
      : null;
}
