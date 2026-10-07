import 'package:edubridge_app/features/lessons/data/lesson_caption_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('loads and parses Arabic captions from the supplied URL', () async {
    final repository = LessonCaptionRepository(get: (uri) async {
      expect(uri.toString(), 'https://example.test/lesson.vtt');
      return http.Response('WEBVTT\n\n00:01.000 --> 00:02.000\nمرحبا', 200,
        headers: {'content-type': 'text/vtt; charset=utf-8'});
    });
    final cues = await repository.load('https://example.test/lesson.vtt');
    expect(cues.single.text, 'مرحبا');
    expect(cues.single.start, const Duration(seconds: 1));
  });
  test('unavailable caption file stays optional', () async {
    final repository = LessonCaptionRepository(get: (_) async => http.Response('', 404));
    expect(await repository.load('https://example.test/lesson.vtt'), isEmpty);
  });
  test('offline captions stay optional', () async {
    final repository = LessonCaptionRepository(get: (_) async => throw http.ClientException('offline'));
    expect(await repository.load('https://example.test/lesson.vtt'), isEmpty);
  });
}
