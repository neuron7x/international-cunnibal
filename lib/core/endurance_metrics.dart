import 'dart:math';

import 'package:international_cunnibal/core/motion_metrics.dart';

class ApertureSample {
  final double t; // seconds
  final Vector2 upperLip; // landmark 13
  final Vector2 lowerLip; // landmark 14
  final Vector2 leftCorner; // landmark 78
  final Vector2 rightCorner; // landmark 308

  const ApertureSample({
    required this.t,
    required this.upperLip,
    required this.lowerLip,
    required this.leftCorner,
    required this.rightCorner,
  });
}

class EnduranceMetricsResult {
  final double aperture; // normalized mean aperture (0-1)
  final double apertureStability; // 0-100
  final double enduranceTime; // seconds above threshold
  final double enduranceScore; // 0-100

  const EnduranceMetricsResult({
    required this.aperture,
    required this.apertureStability,
    required this.enduranceTime,
    required this.enduranceScore,
  });
}

class EnduranceMetrics {
  static const double _eps = 1e-9;

  static EnduranceMetricsResult compute({
    required List<ApertureSample> samples,
    double apertureThreshold = 0.18,
    double? totalWindowSeconds,
  }) {
    if (samples.length < 2) {
      return const EnduranceMetricsResult(
        aperture: 0,
        apertureStability: 0,
        enduranceTime: 0,
        enduranceScore: 0,
      );
    }

    final apertures = samples.map(_apertureForSample).toList();
    final meanAperture =
        apertures.reduce((a, b) => a + b) / max(1, apertures.length);
    final stability = _stability(apertures, meanAperture);
    final enduranceTime =
        _enduranceTime(apertures, samples, threshold: apertureThreshold);

    final totalDuration =
        totalWindowSeconds ?? max(_eps, samples.last.t - samples.first.t);
    final normalizedTime = (enduranceTime / max(_eps, totalDuration)).clamp(0.0, 1.0);
    final apertureScore = (meanAperture * 100).clamp(0.0, 100.0);
    final enduranceScore = (0.4 * apertureScore +
            0.4 * stability +
            0.2 * (normalizedTime * 100))
        .clamp(0.0, 100.0);

    return EnduranceMetricsResult(
      aperture: meanAperture.clamp(0.0, 1.0),
      apertureStability: stability,
      enduranceTime: enduranceTime,
      enduranceScore: enduranceScore,
    );
  }

  static double _apertureForSample(ApertureSample s) {
    final vertical = (s.upperLip - s.lowerLip).magnitude;
    final width = (s.leftCorner - s.rightCorner).magnitude;
    if (width < _eps) return 0;
    return (vertical / width).clamp(0.0, 1.0);
  }

  static double _stability(List<double> apertures, double mean) {
    if (mean < _eps || apertures.length < 2) return 0;
    final variance = apertures
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        apertures.length;
    final std = sqrt(variance);
    final ratio = std / (mean.abs() + _eps);
    return (100 * (1 - ratio)).clamp(0.0, 100.0);
  }

  static double _enduranceTime(
    List<double> apertures,
    List<ApertureSample> samples, {
    required double threshold,
  }) {
    double acc = 0;
    for (var i = 1; i < apertures.length; i++) {
      final onPrev = apertures[i - 1] >= threshold;
      final onNow = apertures[i] >= threshold;
      final dt = max(_eps, samples[i].t - samples[i - 1].t);
      if (onPrev && onNow) {
        acc += dt;
      } else if (onPrev || onNow) {
        // approximate threshold crossing
        acc += dt * 0.5;
      }
    }
    return acc;
  }
}
