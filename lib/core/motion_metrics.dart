import 'dart:math';

class Vector2 {
  final double x;
  final double y;

  const Vector2(this.x, this.y);

  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);
  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);
  Vector2 scale(double k) => Vector2(x * k, y * k);

  double get magnitude => sqrt(x * x + y * y);

  double dot(Vector2 other) => x * other.x + y * other.y;

  Vector2 normalized({double epsilon = 1e-9}) {
    final m = magnitude;
    if (m < epsilon) return const Vector2(0, 0);
    return scale(1 / m);
  }
}

class MotionSample {
  final double t; // seconds
  final Vector2 position;

  const MotionSample({
    required this.t,
    required this.position,
  });
}

class FrequencyResult {
  final double hertz;
  final double confidence;

  const FrequencyResult({
    required this.hertz,
    required this.confidence,
  });
}

class DirectionResult {
  final Vector2 direction; // unit vector
  final double stability; // 0-100

  const DirectionResult({
    required this.direction,
    required this.stability,
  });
}

class PatternMatchResult {
  final double score; // 0-100
  final double mse;

  const PatternMatchResult({
    required this.score,
    required this.mse,
  });
}

class MotionMetricsResult {
  final double consistency; // 0-100
  final FrequencyResult frequency;
  final DirectionResult direction;
  final double intensity; // 0-100
  final PatternMatchResult patternMatch;

  const MotionMetricsResult({
    required this.consistency,
    required this.frequency,
    required this.direction,
    required this.intensity,
    required this.patternMatch,
  });
}

class MotionMetrics {
  static const double _eps = 1e-9;

  static MotionMetricsResult compute({
    required List<MotionSample> samples,
    double expectedAmplitude = 1.0,
    List<MotionSample>? pattern,
    double patternTolerance = 0.1,
  }) {
    if (samples.length < 2) {
      return MotionMetricsResult(
        consistency: 0,
        frequency: const FrequencyResult(hertz: 0, confidence: 0),
        direction: const DirectionResult(direction: Vector2(0, 0), stability: 0),
        intensity: 0,
        patternMatch: const PatternMatchResult(score: 0, mse: 0),
      );
    }

    final displacements = _displacements(samples);
    final totalMag = displacements.fold<double>(
      0,
      (sum, d) => sum + d.magnitude,
    );
    final sampleRate = _sampleRate(samples);

    if (totalMag < _eps) {
      return MotionMetricsResult(
        consistency: 100,
        frequency: const FrequencyResult(hertz: 0, confidence: 0),
        direction: const DirectionResult(direction: Vector2(0, 0), stability: 0),
        intensity: 0,
        patternMatch: pattern == null
            ? const PatternMatchResult(score: 0, mse: 0)
            : _patternMatch(
                samples,
                pattern,
                expectedAmplitude: expectedAmplitude,
                tolerance: patternTolerance,
              ),
      );
    }

    final axis = _principalAxis(samples);
    final directionVector = _direction(displacements);
    final speedStats = _speedStats(samples, displacements);
    final consistency = _consistency(speedStats);
    final freq = _frequency(samples, axis);
    final intensity = _intensity(
      samples,
      speedStats.meanSpeed,
      sampleRate,
    );
    final directionStability = _directionStability(speedStats, directionVector);
    final patternResult = pattern == null
        ? const PatternMatchResult(score: 0, mse: 0)
        : _patternMatch(
            samples,
            pattern,
            expectedAmplitude: expectedAmplitude,
            tolerance: patternTolerance,
          );

    return MotionMetricsResult(
      consistency: consistency,
      frequency: freq,
      direction: DirectionResult(
        direction: directionVector,
        stability: directionStability,
      ),
      intensity: intensity,
      patternMatch: patternResult,
    );
  }

  static List<Vector2> _displacements(List<MotionSample> samples) {
    final out = <Vector2>[];
    for (var i = 1; i < samples.length; i++) {
      out.add(samples[i].position - samples[i - 1].position);
    }
    return out;
  }

  static double _sampleRate(List<MotionSample> samples) {
    if (samples.length < 2) return 0;
    final meanDt =
        (samples.last.t - samples.first.t) / max(1, (samples.length - 1));
    return 1 / max(_eps, meanDt);
  }

  static Vector2 _principalAxis(List<MotionSample> samples) {
    if (samples.isEmpty) return const Vector2(0, 0);
    final mean = _meanPosition(samples);
    double cxx = 0, cxy = 0, cyy = 0;
    for (final s in samples) {
      final dx = s.position.x - mean.x;
      final dy = s.position.y - mean.y;
      cxx += dx * dx;
      cxy += dx * dy;
      cyy += dy * dy;
    }
    cxx /= samples.length;
    cxy /= samples.length;
    cyy /= samples.length;
    final trace = cxx + cyy;
    if (trace < _eps) {
      return const Vector2(0, 0);
    }
    final diff = cxx - cyy;
    final discr = sqrt(diff * diff + 4 * cxy * cxy);
    final lambda1 = 0.5 * (trace + discr);
    final lambda2 = 0.5 * (trace - discr);
    final maxLambda = lambda1 >= lambda2 ? lambda1 : lambda2;
    if (cxy.abs() > _eps) {
      return Vector2(maxLambda - cyy, cxy).normalized();
    }
    return cxx >= cyy ? const Vector2(1, 0) : const Vector2(0, 1);
  }

  static Vector2 _meanPosition(List<MotionSample> samples) {
    var sumX = 0.0;
    var sumY = 0.0;
    for (final s in samples) {
      sumX += s.position.x;
      sumY += s.position.y;
    }
    final n = samples.length;
    return Vector2(sumX / n, sumY / n);
  }

  static _SpeedStats _speedStats(
    List<MotionSample> samples,
    List<Vector2> displacements,
  ) {
    if (displacements.isEmpty) {
      return const _SpeedStats(
        meanSpeed: 0,
        stdSpeed: 0,
        cv: 0,
        jerkStdNormalized: 0,
      );
    }
    final speeds = <double>[];
    for (var i = 0; i < displacements.length; i++) {
      final dt = max(_eps, samples[i + 1].t - samples[i].t);
      speeds.add(displacements[i].magnitude / dt);
    }
    final mean =
        speeds.reduce((a, b) => a + b) / max(1, speeds.length);
    final variance = speeds
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        max(1, speeds.length);
    final std = sqrt(variance);
    final cv = std / (mean + _eps);

    double jerkStd = 0;
    if (speeds.length > 1) {
      final jerks = <double>[];
      for (var i = 1; i < speeds.length; i++) {
        jerks.add(speeds[i] - speeds[i - 1]);
      }
      final jerkMean =
          jerks.reduce((a, b) => a + b) / max(1, jerks.length);
      final jerkVar = jerks
              .map((v) => (v - jerkMean) * (v - jerkMean))
              .reduce((a, b) => a + b) /
          max(1, jerks.length);
      jerkStd = sqrt(jerkVar);
    }
    final jerkStdNormalized = jerkStd / (mean + _eps);
    return _SpeedStats(
      meanSpeed: mean,
      stdSpeed: std,
      cv: cv,
      jerkStdNormalized: jerkStdNormalized,
    );
  }

  static double _consistency(_SpeedStats stats) {
    final base = 100 - stats.cv * 100;
    final penalty = stats.jerkStdNormalized * 20;
    return (base - penalty).clamp(0, 100);
  }

  static double _directionStability(_SpeedStats stats, Vector2 direction) {
    if (direction.magnitude < _eps) return 0;
    final penalty = stats.cv * 50 + stats.jerkStdNormalized * 20;
    return (100 - penalty).clamp(0, 100);
  }

  static FrequencyResult _frequency(List<MotionSample> samples, Vector2 axis) {
    if (samples.length < 4 || axis.magnitude < _eps) {
      return const FrequencyResult(hertz: 0, confidence: 0);
    }

    final sampleRate = _sampleRate(samples);
    final mean = _meanPosition(samples);
    final signal =
        samples.map((s) => (s.position - mean).dot(axis)).toList();
    final signalMean =
        signal.reduce((a, b) => a + b) / max(1, signal.length);
    final centered = signal.map((v) => v - signalMean).toList();
    final r0 = centered.map((v) => v * v).reduce((a, b) => a + b);
    if (r0.abs() < _eps) {
      return const FrequencyResult(hertz: 0, confidence: 0);
    }

    const minHz = 0.5;
    const maxHz = 10.0;
    final minLag = max(1, (sampleRate / maxHz).floor());
    final maxLag = min(
      centered.length - 2,
      max(minLag + 1, (sampleRate / minHz).ceil()),
    );
    if (maxLag <= minLag) {
      return const FrequencyResult(hertz: 0, confidence: 0);
    }

    double bestR = -1;
    int bestLag = minLag;
    final autocorr = <double>[];
    for (var lag = minLag; lag <= maxLag; lag++) {
      double acc = 0;
      for (var i = 0; i + lag < centered.length; i++) {
        acc += centered[i] * centered[i + lag];
      }
      final r = acc / (r0 + _eps);
      autocorr.add(r);
      if (r > bestR) {
        bestR = r;
        bestLag = lag;
      }
    }

    int? peakLag;
    for (var i = 1; i < autocorr.length - 1; i++) {
      final prev = autocorr[i - 1];
      final curr = autocorr[i];
      final next = autocorr[i + 1];
      if (curr >= prev && curr >= next && curr > 0.05) {
        peakLag = minLag + i;
        break;
      }
    }
    final selectedLag = peakLag ?? bestLag;
    if (bestR <= 0 || selectedLag <= 0) {
      return const FrequencyResult(hertz: 0, confidence: 0);
    }

    double refinedLag = selectedLag.toDouble();
    final localIndex = selectedLag - minLag;
    if (localIndex > 0 && localIndex < autocorr.length - 1) {
      final r1 = autocorr[localIndex - 1];
      final r2 = autocorr[localIndex];
      final r3 = autocorr[localIndex + 1];
      final denom = r1 - 2 * r2 + r3;
      if (denom.abs() > _eps) {
        final delta = 0.5 * (r1 - r3) / denom;
        refinedLag = selectedLag + delta.clamp(-1.0, 1.0);
      }
    }
    if (refinedLag <= 0) {
      return const FrequencyResult(hertz: 0, confidence: 0);
    }
    final hz = sampleRate / refinedLag;
    final confidence = (autocorr[localIndex].clamp(0.0, 1.0));
    if (hz <= 0 || hz > sampleRate / 2) {
      return FrequencyResult(hertz: 0, confidence: confidence);
    }
    return FrequencyResult(hertz: hz, confidence: confidence);
  }

  static Vector2 _direction(List<Vector2> displacements) {
    if (displacements.isEmpty) {
      return const Vector2(0, 0);
    }
    final net = displacements
        .fold<Vector2>(const Vector2(0, 0), (s, d) => s + d);
    if (net.magnitude < _eps) {
      return const Vector2(0, 0);
    }
    return net.normalized();
  }

  static double _intensity(
    List<MotionSample> samples,
    double meanSpeed,
    double sampleRate,
  ) {
    if (samples.isEmpty) return 0;
    final spatialScale = _spatialScale(samples);
    const scale = 0.05;
    final denom = spatialScale * sampleRate * scale + _eps;
    final score = 100 * (meanSpeed / denom);
    return score.clamp(0, 100);
  }

  static double _spatialScale(List<MotionSample> samples) {
    final mean = _meanPosition(samples);
    double varX = 0;
    double varY = 0;
    for (final s in samples) {
      final dx = s.position.x - mean.x;
      final dy = s.position.y - mean.y;
      varX += dx * dx;
      varY += dy * dy;
    }
    varX /= max(1, samples.length);
    varY /= max(1, samples.length);
    return sqrt(varX + varY);
  }

  static PatternMatchResult _patternMatch(
    List<MotionSample> observed,
    List<MotionSample> target, {
    required double expectedAmplitude,
    required double tolerance,
  }) {
    if (observed.length < 2 || target.isEmpty) {
      return const PatternMatchResult(score: 0, mse: 0);
    }

    double mse = 0;
    for (final t in target) {
      final interp = _interpolate(observed, t.t);
      final dx = interp.x - t.position.x;
      final dy = interp.y - t.position.y;
      mse += (dx * dx + dy * dy);
    }
    mse /= target.length;
    mse /= pow(max(_eps, expectedAmplitude), 2);

    final denom = tolerance * tolerance + _eps;
    final score = (1 / (1 + mse / denom) * 100).clamp(0.0, 100.0);
    return PatternMatchResult(score: score, mse: mse);
  }

  static Vector2 _interpolate(List<MotionSample> samples, double t) {
    if (t <= samples.first.t) return samples.first.position;
    if (t >= samples.last.t) return samples.last.position;

    var idx = 1;
    while (idx < samples.length && samples[idx].t < t) {
      idx++;
    }
    final a = samples[idx - 1];
    final b = samples[idx];
    final span = max(_eps, b.t - a.t);
    final alpha = (t - a.t) / span;
    return Vector2(
      a.position.x + (b.position.x - a.position.x) * alpha,
      a.position.y + (b.position.y - a.position.y) * alpha,
    );
  }
}

class _SpeedStats {
  final double meanSpeed;
  final double stdSpeed;
  final double cv;
  final double jerkStdNormalized;

  const _SpeedStats({
    required this.meanSpeed,
    required this.stdSpeed,
    required this.cv,
    required this.jerkStdNormalized,
  });
}
