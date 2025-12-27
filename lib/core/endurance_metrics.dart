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
  final double fatigueIndicator; // 0-100
  final double enduranceTime; // seconds above threshold
  final double enduranceScore; // 0-100

  const EnduranceMetricsResult({
    required this.aperture,
    required this.apertureStability,
    required this.fatigueIndicator,
    required this.enduranceTime,
    required this.enduranceScore,
  });
}

class EnduranceMetrics {
  static const double _eps = 1e-9;

  static EnduranceMetricsResult compute({
    required List<ApertureSample> samples,
    double apertureThreshold = 0.18,
    double apertureMin = 0.0,
    double apertureMax = 1.0,
    double? totalWindowSeconds,
  }) {
    if (samples.length < 2) {
      return const EnduranceMetricsResult(
        aperture: 0,
        apertureStability: 0,
        fatigueIndicator: 0,
        enduranceTime: 0,
        enduranceScore: 0,
      );
    }

    final boundedThreshold = apertureThreshold.clamp(apertureMin, apertureMax);
    final metricsCache = _EnduranceMetricsCache.fromSamples(
      samples,
      apertureMin: apertureMin,
      apertureMax: apertureMax,
    );
    final meanAperture = metricsCache.meanAperture;
    final stability = metricsCache.stability;
    final enduranceTime = _enduranceTime(
      metricsCache.apertures,
      samples,
      threshold: boundedThreshold,
    );
    final fatigue = metricsCache.fatigue;

    final totalDuration =
        totalWindowSeconds ?? max(_eps, samples.last.t - samples.first.t);
    final normalizedTime = (enduranceTime / max(_eps, totalDuration)).clamp(0.0, 1.0);
    final apertureScore = (meanAperture * 100).clamp(0.0, 100.0);
    final enduranceScore = _score(
      apertureScore: apertureScore,
      stability: stability,
      normalizedTime: normalizedTime,
      fatigue: fatigue,
    );

    return EnduranceMetricsResult(
      aperture: meanAperture.clamp(0.0, 1.0),
      apertureStability: stability,
      fatigueIndicator: fatigue,
      enduranceTime: enduranceTime,
      enduranceScore: enduranceScore,
    );
  }

  static double _apertureForSample(
    ApertureSample s, {
    required double apertureMin,
    required double apertureMax,
  }) {
    final vertical = (s.upperLip - s.lowerLip).magnitude;
    final width = (s.leftCorner - s.rightCorner).magnitude;
    if (width < _eps) return 0;
    return (vertical / width).clamp(apertureMin, apertureMax);
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

  /// Endurance score combines stability, time-on-target, and mean aperture.
  ///
  /// Score = 0.4 * stability + 0.35 * timeScore + 0.25 * apertureScore
  /// Fatigue penalty = 0.3 * fatigueIndicator
  ///
  /// The final score is bounded in [0, 100].
  static double _score({
    required double apertureScore,
    required double stability,
    required double normalizedTime,
    required double fatigue,
  }) {
    final timeScore = (normalizedTime * 100).clamp(0.0, 100.0);
    final base = 0.4 * stability + 0.35 * timeScore + 0.25 * apertureScore;
    final penalty = 0.3 * fatigue;
    return (base - penalty).clamp(0.0, 100.0);
  }
}

class _EnduranceMetricsCache {
  final List<double> apertures;
  final double meanAperture;
  final double stability;
  final double fatigue;

  _EnduranceMetricsCache({
    required this.apertures,
    required this.meanAperture,
    required this.stability,
    required this.fatigue,
  });

  factory _EnduranceMetricsCache.fromSamples(
    List<ApertureSample> samples, {
    required double apertureMin,
    required double apertureMax,
  }) {
    final count = samples.length;
    final apertures = List<double>.filled(count, 0);
    double sum = 0;
    double sumSq = 0;
    double firstSum = 0;
    double firstSumSq = 0;
    int firstCount = 0;
    double secondSum = 0;
    double secondSumSq = 0;
    int secondCount = 0;

    final mid = (count / 2).floor();

    for (var i = 0; i < count; i++) {
      final aperture = EnduranceMetrics._apertureForSample(
        samples[i],
        apertureMin: apertureMin,
        apertureMax: apertureMax,
      );
      apertures[i] = aperture;
      sum += aperture;
      sumSq += aperture * aperture;
      if (i < mid) {
        firstSum += aperture;
        firstSumSq += aperture * aperture;
        firstCount += 1;
      } else {
        secondSum += aperture;
        secondSumSq += aperture * aperture;
        secondCount += 1;
      }
    }

    final meanAperture = count == 0 ? 0.0 : sum / max(1, count);
    final stability = _stabilityFromStats(
      meanAperture,
      sumSq,
      count,
    );

    final firstMean =
        firstCount == 0 ? 0.0 : firstSum / max(1, firstCount);
    final secondMean =
        secondCount == 0 ? 0.0 : secondSum / max(1, secondCount);

    final firstStability =
        _stabilityFromStats(firstMean, firstSumSq, firstCount);
    final secondStability =
        _stabilityFromStats(secondMean, secondSumSq, secondCount);

    final fatigue = _fatigueFromStability(firstStability, secondStability);

    return _EnduranceMetricsCache(
      apertures: apertures,
      meanAperture: meanAperture,
      stability: stability,
      fatigue: fatigue,
    );
  }

  static double _stabilityFromStats(
    double mean,
    double sumSq,
    int count,
  ) {
    if (mean < EnduranceMetrics._eps || count < 2) return 0;
    final variance = (sumSq / max(1, count)) - mean * mean;
    final std = sqrt(max(0.0, variance));
    final ratio = std / (mean.abs() + EnduranceMetrics._eps);
    return (100 * (1 - ratio)).clamp(0.0, 100.0);
  }

  static double _fatigueFromStability(
    double firstStability,
    double secondStability,
  ) {
    if (firstStability < EnduranceMetrics._eps) return 0;
    final dropRatio =
        ((firstStability - secondStability) / max(EnduranceMetrics._eps, firstStability))
            .clamp(0.0, 1.0);
    return (dropRatio * 100).clamp(0.0, 100.0);
  }
}
