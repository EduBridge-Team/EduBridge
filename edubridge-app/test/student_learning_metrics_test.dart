import 'dart:convert';

import 'package:edubridge_app/features/students/data/student_learning_metrics_repository.dart';
import 'package:edubridge_app/features/students/domain/student_learning_metrics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('only completed visible lessons count; repeated progress does not inflate completion', () {
    final metrics = StudentLearningMetrics.fromData(
      lessons: [
        {'id': 1},
        {'id': '2'},
        {'id': 3},
      ],
      progress: [
        {'lesson_id': '1', 'status': 'done'},
        {'lesson_id': 1, 'status': 'done'},
        {'lesson_id': 2, 'status': 'in_progress'},
        {'lesson_id': 99, 'status': 'done'},
        {'lesson_id': null, 'status': 'done'},
        'invalid',
      ],
    );
    expect(metrics.lessonsCount, 3);
    expect(metrics.completionPercent, 33);
  });

  test(
    'missing, empty and valid zero progress retain distinct display states',
    () {
      final missing = StudentLearningMetrics.fromData(
        lessons: null,
        progress: [],
      );
      expect(missing.lessonsCount, isNull);
      expect(missing.completionPercent, isNull);
      final empty = StudentLearningMetrics.fromData(lessons: [], progress: []);
      expect(empty.lessonsCount, 0);
      expect(empty.completionPercent, isNull);
      final unavailable = StudentLearningMetrics.fromData(
        lessons: [
          {'id': 1},
        ],
        progress: null,
      );
      expect(unavailable.lessonsCount, 1);
      expect(unavailable.completionPercent, isNull);
      expect(
        StudentLearningMetrics.fromData(
          lessons: [
            {'id': 1},
          ],
          progress: [],
        ).completionPercent,
        0,
      );
    },
  );

  for (final failedLessons in [false, true]) {
    test(
      'repository keeps partial HTTP failures unknown (lessons=$failedLessons)',
      () async {
        final paths = <String>[];
        final repository = StudentLearningMetricsRepository(
          get: (path) async {
            paths.add(path);
            final lessons = path.endsWith('/lessons');
            final failed = lessons == failedLessons;
            return http.Response(
              jsonEncode(
                lessons
                    ? {
                        'lessons': [
                          {'id': 1},
                        ],
                      }
                    : {'progress': []},
              ),
              failed ? 403 : 200,
            );
          },
        );
        final metrics = await repository.load(5);
        expect(paths, ['/children/5/lessons', '/progress/child/5']);
        expect(metrics.lessonsCount, failedLessons ? isNull : 1);
        expect(metrics.completionPercent, isNull);
      },
    );
  }

  test(
    'repository preserves completion from valid child-scoped responses',
    () async {
      final repository = StudentLearningMetricsRepository(
        get: (path) async => http.Response(
          jsonEncode(
            path.endsWith('/lessons')
                ? {
                    'lessons': [
                      {'id': 2},
                    ],
                  }
                : {
                    'progress': [
                      {'lesson_id': 2, 'status': 'done'},
                    ],
                  },
          ),
          200,
        ),
      );
      expect((await repository.load(5)).completionPercent, 100);
    },
  );

  test(
    'malformed data remains unknown; transport failure reaches coordinator',
    () async {
      final malformed = StudentLearningMetricsRepository(
        get: (_) async => http.Response('invalid', 200),
      );
      expect((await malformed.load(5)).lessonsCount, isNull);
      final offline = StudentLearningMetricsRepository(
        get: (_) async => throw http.ClientException('offline'),
      );
      await expectLater(offline.load(5), throwsA(isA<http.ClientException>()));
    },
  );
}
