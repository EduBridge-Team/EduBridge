import '../../../services/lesson_captions.dart';

/// Pure playback decisions; controllers and lifecycle subscriptions stay in UI.
class LessonMediaPolicy {
  static String captionAt(List<LessonCaption> captions, Duration position) {
    for (final caption in captions) {
      if (position >= caption.start && position < caption.end) return caption.text;
    }
    return '';
  }

  static Duration signTarget(Duration mainPosition, Duration signDuration) =>
      mainPosition > signDuration ? signDuration : mainPosition;

  static bool needsSignSeek(Duration position, Duration target) =>
      (position - target).inMilliseconds.abs() > 350;

  static bool shouldPlaySign({
    required bool foreground,
    required bool visible,
    required bool mainPlaying,
    required Duration target,
    required Duration duration,
  }) => foreground && visible && mainPlaying && target < duration;

  static String nextSignPosition(String current) {
    const positions = ['bottom_right', 'bottom_left', 'top_right', 'top_left'];
    return positions[(positions.indexOf(current) + 1) % positions.length];
  }
}
