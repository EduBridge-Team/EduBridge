import 'package:edubridge_app/services/lesson_captions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WebVTT minute timestamps, CRLF and cue settings stay synchronized', () {
    final cues = parseLessonCaptions('WEBVTT\r\n\r\nlesson-1\r\n01:02.125 --> 01:04.500 align:start\r\n<b>مرحبا</b>\r\nسطر آخر\r\n');
    expect(cues, hasLength(1));
    expect(cues.single.start, const Duration(minutes: 1, seconds: 2, milliseconds: 125));
    expect(cues.single.end, const Duration(minutes: 1, seconds: 4, milliseconds: 500));
    expect(cues.single.text, 'مرحبا\nسطر آخر');
  });
  test('SubRip hours and comma fractions are parsed and invalid cues ignored', () {
    final cues = parseLessonCaptions('1\n01:00:02,250 --> 01:00:03,001\nنص\n\n2\ninvalid --> 00:00:03.000\nخطأ\n\n3\n00:06.000 --> 00:05.000\nمعكوس');
    expect(cues, hasLength(1));
    expect(cues.single.start, const Duration(hours: 1, seconds: 2, milliseconds: 250));
    expect(cues.single.end, const Duration(hours: 1, seconds: 3, milliseconds: 1));
  });
}
