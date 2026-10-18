import 'dart:math' as math;

/// A camera-independent gaze sample in normalized screen coordinates.
/// Camera frames and images must never be passed to this layer.
class GazeSample {
  const GazeSample({
    required this.x,
    required this.y,
    required this.confidence,
    required this.timestamp,
  });

  final double x;
  final double y;
  final double confidence;
  final Duration timestamp;
}

/// Filters noisy eye-gaze estimates; does not generate pointer/click events.
///
/// Consumers must explicitly opt in, obtain camera permission in a separate
/// layer, and show a visible indicator while tracking is active.
class GazePointerFilter {
  GazePointerFilter({
    this.smoothing = 0.35,
    this.minimumConfidence = 0.65,
    this.maximumSampleGap = const Duration(milliseconds: 500),
  }) : assert(smoothing > 0 && smoothing <= 1),
       assert(minimumConfidence >= 0 && minimumConfidence <= 1),
       assert(!maximumSampleGap.isNegative);

  final double smoothing;
  final double minimumConfidence;
  final Duration maximumSampleGap;

  GazeSample? _last;

  GazeSample? get position => _last;

  /// Returns null for low confidence, invalid coordinates or stale samples.
  /// Such samples clear the cursor rather than leaving a potentially
  /// misleading point visible.
  GazeSample? add(GazeSample sample) {
    if (!sample.x.isFinite ||
        !sample.y.isFinite ||
        !sample.confidence.isFinite ||
        sample.x < 0 ||
        sample.x > 1 ||
        sample.y < 0 ||
        sample.y > 1 ||
        sample.confidence < minimumConfidence) {
      reset();
      return null;
    }

    final previous = _last;
    if (previous != null && sample.timestamp <= previous.timestamp) {
      reset();
      return null;
    }
    if (previous == null ||
        sample.timestamp - previous.timestamp > maximumSampleGap) {
      _last = sample;
      return _last;
    }

    _last = GazeSample(
      x: _clamp(previous.x + smoothing * (sample.x - previous.x)),
      y: _clamp(previous.y + smoothing * (sample.y - previous.y)),
      confidence: sample.confidence,
      timestamp: sample.timestamp,
    );
    return _last;
  }

  void reset() => _last = null;

  double _clamp(double value) => math.max(0, math.min(1, value));
}
