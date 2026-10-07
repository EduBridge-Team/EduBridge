import 'package:edubridge_app/features/lessons/domain/lesson_media_policy.dart';
import 'package:edubridge_app/services/lesson_captions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const second = Duration(seconds: 1);
  const end = Duration(seconds: 2);
  const captions = [LessonCaption(start: second, end: end, text: 'نص'),
    LessonCaption(start: second, end: end, text: 'آخر')];
  test('captions include start, exclude end and preserve first overlap', () {
    expect(LessonMediaPolicy.captionAt(captions, Duration.zero), '');
    expect(LessonMediaPolicy.captionAt(captions, second), 'نص');
    expect(LessonMediaPolicy.captionAt(captions, end), '');
    expect(LessonMediaPolicy.captionAt([], second), '');
  });
  test('sign synchronization clamps to sign duration', () {
    expect(LessonMediaPolicy.signTarget(second, end), second);
    expect(LessonMediaPolicy.signTarget(end, second), second);
  });
  test('seek tolerance preserves strict 350 millisecond boundary both ways', () {
    expect(LessonMediaPolicy.needsSignSeek(const Duration(milliseconds: 350), Duration.zero), false);
    expect(LessonMediaPolicy.needsSignSeek(const Duration(milliseconds: 351), Duration.zero), true);
    expect(LessonMediaPolicy.needsSignSeek(Duration.zero, const Duration(milliseconds: 351)), true);
  });
  test('sign playback requires foreground, visibility, main playback and remaining duration', () {
    for (final foreground in [false, true]) {
      for (final visible in [false, true]) {
        for (final playing in [false, true]) {
          expect(LessonMediaPolicy.shouldPlaySign(foreground: foreground,
            visible: visible, mainPlaying: playing, target: second, duration: end),
            foreground && visible && playing);
        }
      }
    }
    expect(LessonMediaPolicy.shouldPlaySign(foreground: true, visible: true,
      mainPlaying: true, target: end, duration: end), false);
  });
  test('overlay positions cycle in existing order and unknown position resets', () {
    var position = 'bottom_right';
    for (final expected in ['bottom_left', 'top_right', 'top_left', 'bottom_right']) {
      position = LessonMediaPolicy.nextSignPosition(position);
      expect(position, expected);
    }
    expect(LessonMediaPolicy.nextSignPosition('unknown'), 'bottom_right');
  });
}
