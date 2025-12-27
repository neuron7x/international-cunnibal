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

    final direction = _direction(displacements);
    final axis = direction.direction;
    final speeds = _projectedSpeeds(samples, displacements, axis);
    final speedMagnitudes = speeds.map((v) => v.abs()).toList();
    final normalizedSpeeds = speedMagnitudes
        .map((v) => v / max(_eps, expectedAmplitude))
        .toList();

    final consistency = _consistency(speedMagnitudes);
    final freq = _frequency(samples, axis);
    final intensity = _intensity(normalizedSpeeds);
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
      direction: direction,
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

  static List<double> _projectedSpeeds(
    List<MotionSample> samples,
    List<Vector2> displacements,
    Vector2 axis,
  ) {
    final speeds = <double>[];
    if (axis.magnitude < _eps) {
      return List<double>.filled(displacements.length, 0);
    }
    for (var i = 0; i < displacements.length; i++) {
      final dt = max(_eps, samples[i + 1].t - samples[i].t);
      final signed = displacements[i].dot(axis);
      speeds.add(signed / dt);
    }
    return speeds;
  }

  static double _consistency(List<double> speeds) {
    if (speeds.isEmpty) return 0;
    final mean = speeds.reduce((a, b) => a + b) / speeds.length;
    final variance = speeds.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
        speeds.length;
    final std = sqrt(variance);
    final ratio = std / (mean + _eps);
    final score = 100 * (1 - ratio);
    return score.clamp(0, 100);
  }

  static FrequencyResult _frequency(List<MotionSample> samples, Vector2 axis) {
    if (samples.length < 4 || axis.magnitude < _eps) {
      return const FrequencyResult(hertz: 0, confidence: 0);
    }

    final meanDt =
        (samples.last.t - samples.first.t) / max(1, (samples.length - 1));
    final sampleRate = 1 / max(_eps, meanDt);

    final projections = samples.map((s) => s.position.dot(axis)).toList();
    final mean =
        projections.reduce((a, b) => a + b) / projections.length;
    final centered = projections.map((v) => v - mean).toList();
    final windowed = _applyHann(centered);
    final r0 = windowed.map((v) => v * v).reduce((a, b) => a + b);
    if (r0.abs() < _eps) {
      return const FrequencyResult(hertz: 0, confidence: 0);
    }

    double bestR = 0;
    int bestLag = 0;
    final maxLag = windowed.length ~/ 2;
    for (var lag = 2; lag <= maxLag; lag++) {
      double acc = 0;
      for (var i = 0; i + lag < windowed.length; i++) {
        acc += windowed[i] * windowed[i + lag];
      }
      if (acc > bestR) {
        bestR = acc;
        bestLag = lag;
      }
    }

    if (bestLag == 0 || bestR.abs() < _eps) {
      return const FrequencyResult(hertz: 0, confidence: 0);
    }

    final hz = sampleRate / bestLag;
    final confidence = (bestR / (r0 + _eps)).clamp(0.0, 1.0);
    if (hz <= 0 || hz > sampleRate / 2) {
      return FrequencyResult(hertz: 0, confidence: confidence);
    }
    if (confidence < 0.2) {
      return FrequencyResult(hertz: 0, confidence: confidence);
    }
    return FrequencyResult(hertz: hz, confidence: confidence);
  }

  static DirectionResult _direction(List<Vector2> displacements) {
    if (displacements.isEmpty) {
      return const DirectionResult(direction: Vector2(0, 0), stability: 0);
    }

    final meanX = displacements.fold<double>(0, (s, d) => s + d.x) /
        displacements.length;
    final meanY = displacements.fold<double>(0, (s, d) => s + d.y) /
        displacements.length;

    double cxx = 0, cxy = 0, cyy = 0;
    for (final d in displacements) {
      final dx = d.x - meanX;
      final dy = d.y - meanY;
      cxx += dx * dx;
      cxy += dx * dy;
      cyy += dy * dy;
    }
    cxx /= displacements.length;
    cxy /= displacements.length;
    cyy /= displacements.length;

    final trace = cxx + cyy;
    Vector2 eigen;
    if (trace.abs() >= _eps) {
      final diff = cxx - cyy;
      final discr = sqrt(diff * diff + 4 * cxy * cxy);
      final lambda1 = 0.5 * (trace + discr);
      final lambda2 = 0.5 * (trace - discr);
      final maxLambda = lambda1 >= lambda2 ? lambda1 : lambda2;

      if (cxy.abs() > _eps) {
        eigen = Vector2(maxLambda - cyy, cxy).normalized();
      } else {
        eigen = cxx >= cyy ? const Vector2(1, 0) : const Vector2(0, 1);
      }
    } else {
      eigen = const Vector2(0, 0);
    }

    final net = displacements
        .fold<Vector2>(const Vector2(0, 0), (s, d) => s + d);
    if (eigen.magnitude < _eps) {
      eigen = net.normalized();
    }
    if (eigen.magnitude < _eps) {
      return const DirectionResult(direction: Vector2(0, 0), stability: 0);
    }
    if (net.dot(eigen) < 0) {
      eigen = eigen.scale(-1);
    }

    var valid = 0;
    var sumCos = 0.0;
    for (final d in displacements) {
      final mag = d.magnitude;
      if (mag < _eps) continue;
      final u = d.scale(1 / mag);
      sumCos += (u.dot(eigen)).abs();
      valid++;
    }
    final stability =
        valid == 0 ? 0.0 : (100 * (sumCos / valid)).clamp(0.0, 100.0);
    return DirectionResult(direction: eigen, stability: stability);
  }

  static double _intensity(List<double> normalizedSpeeds) {
    if (normalizedSpeeds.isEmpty) return 0;
    final mean = normalizedSpeeds.reduce((a, b) => a + b) /
        normalizedSpeeds.length;
    final score = 100 * mean;
    return score.clamp(0, 100);
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

  static List<double> _applyHann(List<double> data) {
    final n = data.length;
    if (n <= 1) return data;
    return List.generate(n, (i) {
      final w = 0.5 * (1 - cos(2 * pi * i / (n - 1)));
      return data[i] * w;
    });
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
