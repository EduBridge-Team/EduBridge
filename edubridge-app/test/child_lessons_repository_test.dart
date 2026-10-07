import 'dart:async';
import 'dart:convert';
import 'package:edubridge_app/features/lessons/data/child_lessons_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('loads both child-scoped endpoints concurrently and preserves media', () async {
    final requests = <String>[];
    final lessons = Completer<http.Response>();
    final progress = Completer<http.Response>();
    final repository = ChildLessonsRepository(get: (path) {
      requests.add(path);
      return path.contains('/lessons') ? lessons.future : progress.future;
    });
    final pending = repository.load(42);
    expect(requests, ['/children/42/lessons', '/progress/child/42']);
    lessons.complete(http.Response(jsonEncode({'lessons': [
      {'id': 7, 'title': 'درس', 'video_url': 'video', 'caption_url': 'captions',
       'sign_language_url': 'sign', 'audio_description': 'وصف'}
    ]}), 200));
    progress.complete(http.Response(jsonEncode({'progress': [
      {'lesson_id': 7, 'status': 'done'},
      {'lesson_id': 7, 'status': 'done'},
      {'lesson_id': 8, 'status': 'started'},
      {'lesson_id': '9', 'status': 'done'}
    ]}), 200));
    final result = await pending;
    expect(result.error, isNull);
    expect(result.doneLessonIds, {7});
    expect(result.lessons.single['caption_url'], 'captions');
    expect(result.lessons.single['sign_language_url'], 'sign');
    expect(result.lessons.single['audio_description'], 'وصف');
  });

  test('progress permission failure still allows loading assigned lessons', () async {
    final repository = ChildLessonsRepository(get: (path) async =>
      path.contains('/lessons') ? http.Response('{"lessons":[{"id":1}]}', 200)
          : http.Response('forbidden', 403));
    final result = await repository.load(1);
    expect(result.error, isNull);
    expect(result.lessons, hasLength(1));
    expect(result.doneLessonIds, isEmpty);
  });

  test('lesson permission failure preserves the server message', () async {
    final repository = ChildLessonsRepository(get: (_) async =>
      http.Response('{"error":"denied"}', 403));
    expect((await repository.load(1)).error, 'denied');
  });

  test('lesson failure without message preserves the fallback', () async {
    final repository = ChildLessonsRepository(get: (_) async => http.Response('{}', 500));
    expect((await repository.load(1)).error, 'تعذّر جلب الدروس');
  });

  test('missing lesson and progress lists produce an empty result', () async {
    final repository = ChildLessonsRepository(get: (_) async => http.Response('{}', 200));
    final result = await repository.load(1);
    expect(result.error, isNull);
    expect(result.lessons, isEmpty);
    expect(result.doneLessonIds, isEmpty);
  });

  test('invalid successful progress preserves the network error message', () async {
    final repository = ChildLessonsRepository(get: (path) async =>
      http.Response(path.contains('/lessons') ? '{"lessons":[]}' : 'invalid', 200));
    expect((await repository.load(1)).error, 'تعذّر الاتصال بالسيرفر');
  });

  test('network exception preserves the existing message', () async {
    final repository = ChildLessonsRepository(get: (_) async => throw http.ClientException('offline'));
    expect((await repository.load(1)).error, 'تعذّر الاتصال بالسيرفر');
  });
}
