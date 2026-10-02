// Shared, testable Arabic matching rules for voice navigation.
String normalizeVoiceText(String input) => input.toLowerCase()
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ئ', 'ي').replaceAll('ؤ', 'و')
    .replaceAll('ى', 'ي').replaceAll('ة', 'ه')
    .replaceAll(RegExp(r'[،.,!؟?:;\-]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ').trim();

bool matchesVoiceText(String text, List<String> phrases) {
  final normalized = ' ${normalizeVoiceText(text)} ';
  return phrases.any((phrase) => normalized.contains(' ${normalizeVoiceText(phrase)} '));
}

Map<String, dynamic>? findVoiceChild(String text, List<Map<String, dynamic>> children) {
  final exact = children.where((child) {
    final name = normalizeVoiceText((child['name'] ?? '').toString());
    return name.isNotEmpty && matchesVoiceText(text, [name]);
  }).toList();
  if (exact.length == 1) return exact.single;
  if (exact.length > 1) return null;
  final partial = children.where((child) => normalizeVoiceText((child['name'] ?? '').toString())
    .split(' ').any((word) => word.length >= 3 && matchesVoiceText(text, [word]))).toList();
  return partial.length == 1 ? partial.single : null;
}
