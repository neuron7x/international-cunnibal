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

    final minAperture = min(apertureMin, apertureMax);
    final maxAperture = max(apertureMin, apertureMax);
    final boundedThreshold = apertureThreshold.clamp(minAperture, maxAperture);
    final apertures = samples
        .map((sample) => _apertureForSample(
              sample,
              apertureMin: minAperture,
              apertureMax: maxAperture,
            ))
        .toList();
    final meanAperture = _mean(apertures);
    final stability = _stability(apertures, meanAperture);
    final enduranceTime =
        _enduranceTime(apertures, samples, threshold: boundedThreshold);
    final fatigue = _fatigue(apertures);

    final rawDuration = samples.last.t - samples.first.t;
    final safeDuration = rawDuration.isFinite ? rawDuration : 0.0;
    final totalDuration =
        totalWindowSeconds ?? max(_eps, safeDuration);
    final normalizedTime =
        _clampRatio(enduranceTime / max(_eps, totalDuration));
    final apertureScore = _clampScore(meanAperture * 100);
    final enduranceScore = _score(
      apertureScore: apertureScore,
      stability: stability,
      normalizedTime: normalizedTime,
      fatigue: fatigue,
    );

    return EnduranceMetricsResult(
      aperture: _clampRatio(meanAperture),
      apertureStability: _clampScore(stability),
      fatigueIndicator: _clampScore(fatigue),
      enduranceTime: _finiteOrZero(enduranceTime),
      enduranceScore: _clampScore(enduranceScore),
    );
  }

  static double _apertureForSample(
    ApertureSample s, {
    required double apertureMin,
    required double apertureMax,
  }) {
    final vertical = (s.upperLip - s.lowerLip).magnitude;
    final width = (s.leftCorner - s.rightCorner).magnitude;
    if (!vertical.isFinite || !width.isFinite || width < _eps) return 0;
    final value = vertical / width;
    if (!value.isFinite) return 0;
    return value.clamp(apertureMin, apertureMax);
  }

  static double _mean(List<double> values) {
    if (values.isEmpty) return 0;
    var sum = 0.0;
    for (final v in values) {
      sum += v;
    }
    return sum / max(1, values.length);
  }

  static double _stability(List<double> apertures, double mean) {
    if (!mean.isFinite || mean.abs() < _eps || apertures.length < 2) return 0;
    var sum = 0.0;
    for (final v in apertures) {
      final diff = v - mean;
      sum += diff * diff;
    }
    final variance = sum / apertures.length;
    final std = sqrt(variance);
    final ratio = std / (mean.abs() + _eps);
    return _clampScore(100 * (1 - ratio));
  }

  static double _fatigue(List<double> apertures) {
    if (apertures.length < 4) return 0;
    final mid = (apertures.length / 2).floor();
    final firstHalf = apertures.sublist(0, mid);
    final secondHalf = apertures.sublist(mid);
    final firstMean = _mean(firstHalf);
    final secondMean = _mean(secondHalf);
    final firstStability = _stability(firstHalf, firstMean);
    final secondStability = _stability(secondHalf, secondMean);
    if (firstStability < _eps) return 0;
    final dropRatio =
        ((firstStability - secondStability) / max(_eps, firstStability))
            .clamp(0.0, 1.0);
    return _clampScore(dropRatio * 100);
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
      final rawDt = samples[i].t - samples[i - 1].t;
      final dt = rawDt.isFinite ? max(_eps, rawDt) : 0.0;
      if (onPrev && onNow) {
        acc += dt;
      } else if (onPrev || onNow) {
        // approximate threshold crossing
        acc += dt * 0.5;
      }
    }
    return _finiteOrZero(acc);
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
    final timeScore = _clampScore(normalizedTime * 100);
    final base = 0.4 * stability + 0.35 * timeScore + 0.25 * apertureScore;
    final penalty = 0.3 * fatigue;
    return _clampScore(base - penalty);
  }

  static double _clampScore(double value) {
    if (!value.isFinite) return 0.0;
    return value.clamp(0.0, 100.0);
  }

  static double _clampRatio(double value) {
    if (!value.isFinite) return 0.0;
    return value.clamp(0.0, 1.0);
  }

  static double _finiteOrZero(double value) => value.isFinite ? value : 0.0;
}
