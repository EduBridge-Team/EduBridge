import 'package:edubridge_app/services/accessibility/gaze_pointer_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GazeSample point(double x, double y, int ms, {double confidence = 0.9}) =>
      GazeSample(x: x, y: y, confidence: confidence,
          timestamp: Duration(milliseconds: ms));

  group('GazePointerFilter', () {
    test('first valid point passes through; subsequent points are smoothed', () {
      final filter = GazePointerFilter(smoothing: 0.5);
      expect(filter.add(point(0.2, 0.4, 100))!.x, 0.2);
      final next = filter.add(point(0.8, 0.6, 120))!;
      expect(next.x, closeTo(0.5, 0.0001));
      expect(next.y, closeTo(0.5, 0.0001));
    });

    test('low confidence and invalid coordinates clear tracked position', () {
      final filter = GazePointerFilter();
      filter.add(point(0.4, 0.5, 100));
      expect(filter.add(point(0.8, 0.8, 120, confidence: 0.1)), isNull);
      expect(filter.position, isNull);
      filter.add(point(0.4, 0.5, 140));
      expect(filter.add(point(double.nan, 0.5, 160)), isNull);
      expect(filter.position, isNull);
    });

    test('old and out-of-order frames cannot move cursor', () {
      final filter = GazePointerFilter();
      filter.add(point(0.1, 0.2, 100));
      expect(filter.add(point(0.9, 0.9, 100)), isNull);
      expect(filter.position, isNull);
    });

    test('large gap resets smoothing so cursor does not drift', () {
      final filter = GazePointerFilter(smoothing: 0.1);
      filter.add(point(0.1, 0.1, 100));
      expect(filter.add(point(0.9, 0.9, 800))!.x, 0.9);
    });

    test('reset clears the current point', () {
      final filter = GazePointerFilter();
      filter.add(point(0.5, 0.5, 100));
      filter.reset();
      expect(filter.position, isNull);
    });
  });
}
