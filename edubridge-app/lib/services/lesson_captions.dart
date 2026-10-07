/// A timed cue shared by WebVTT and SubRip lesson captions.
class LessonCaption {
  final Duration start;
  final Duration end;
  final String text;
  const LessonCaption({required this.start, required this.end, required this.text});
}

List<LessonCaption> parseLessonCaptions(String content) {
  Duration? timestamp(String value) {
    final match = RegExp(r'^(?:(\d+):)?(\d{2}):(\d{2})[.,](\d{3})$').firstMatch(value);
    if (match == null) return null;
    final minutes = int.parse(match[2]!);
    final seconds = int.parse(match[3]!);
    if (minutes > 59 || seconds > 59) return null;
    return Duration(hours: int.parse(match[1] ?? '0'), minutes: minutes,
      seconds: seconds, milliseconds: int.parse(match[4]!));
  }
  final cues = <LessonCaption>[];
  final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  for (final block in normalized.split(RegExp(r'\n[ \t]*\n'))) {
    final lines = block.trim().split('\n');
    if (lines.first.startsWith('NOTE') || lines.first == 'STYLE' || lines.first == 'REGION') continue;
    final index = lines.indexWhere((line) => line.contains('-->'));
    if (index < 0 || index + 1 >= lines.length) continue;
    final times = lines[index].split('-->');
    if (times.length != 2) continue;
    final start = timestamp(times[0].trim());
    final end = timestamp(times[1].trim().split(RegExp(r'\s+')).first);
    if (start == null || end == null || end <= start) continue;
    final text = lines.skip(index + 1).join('\n').replaceAll(RegExp(r'<[^>]*>'), '');
    cues.add(LessonCaption(start: start, end: end, text: text));
  }
  cues.sort((a, b) => a.start.compareTo(b.start));
  return cues;
}
