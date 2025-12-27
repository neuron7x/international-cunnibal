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

class MotionMetricsCache {
  final List<MotionSample> samples;
  final List<Vector2> displacements;
  final double sampleRate;
  final Vector2 meanPosition;
  final Vector2 principalAxis;
  final _SpeedStats speedStats;
  final double spatialScale;
  final List<double> centeredSignal;
  final double signalEnergy;

  MotionMetricsCache({
    required this.samples,
    required this.displacements,
    required this.sampleRate,
    required this.meanPosition,
    required this.principalAxis,
    required this.speedStats,
    required this.spatialScale,
    required this.centeredSignal,
    required this.signalEnergy,
  });
}

class MotionMetrics {
  static const double _eps = 1e-9;
  static final Expando<MotionMetricsCache> _cache =
      Expando<MotionMetricsCache>('motion_metrics_cache');

  static MotionMetricsResult compute({
    required List<MotionSample> samples,
    double expectedAmplitude = 1.0,
    List<MotionSample>? pattern,
    double patternTolerance = 0.1,
    MotionMetricsCache? cache,
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

    final derivedCache = cache ?? _cache[samples] ?? _buildCache(samples);
    _cache[samples] = derivedCache;
    final displacements = derivedCache.displacements;
    final totalMag = displacements.fold<double>(
      0,
      (sum, d) => sum + d.magnitude,
    );
    final sampleRate = derivedCache.sampleRate;

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

    final axis = derivedCache.principalAxis;
    final directionVector = _directionFromAxis(axis, displacements);
    final speedStats = derivedCache.speedStats;
    final consistency = _consistency(speedStats);
    final freq = _frequency(derivedCache);
    final intensity = _intensity(
      speedStats.meanSpeed,
      sampleRate,
      derivedCache.spatialScale,
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

  static MotionMetricsCache _buildCache(List<MotionSample> samples) {
    final displacements = _displacements(samples);
    final sampleRate = _sampleRate(samples);
    final meanPosition = _meanPosition(samples);
    final principalAxis = _principalAxis(samples, meanPosition);
    final speedStats = _speedStats(samples, displacements);
    final spatialScale = _spatialScale(samples, meanPosition);

    final centeredSignal = <double>[];
    var signalEnergy = 0.0;
    if (samples.length >= 4 && principalAxis.magnitude >= _eps) {
      final signal = samples
          .map((s) => (s.position - meanPosition).dot(principalAxis))
          .toList();
      final signalMean =
          signal.reduce((a, b) => a + b) / max(1, signal.length);
      for (final value in signal) {
        final centered = value - signalMean;
        centeredSignal.add(centered);
        signalEnergy += centered * centered;
      }
    }

    return MotionMetricsCache(
      samples: samples,
      displacements: displacements,
      sampleRate: sampleRate,
      meanPosition: meanPosition,
      principalAxis: principalAxis,
      speedStats: speedStats,
      spatialScale: spatialScale,
      centeredSignal: centeredSignal,
      signalEnergy: signalEnergy,
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

  static Vector2 _principalAxis(
    List<MotionSample> samples,
    Vector2 mean,
  ) {
    if (samples.isEmpty) return const Vector2(0, 0);
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
    double sum = 0;
    double sumSq = 0;
    double jerkSum = 0;
    double jerkSumSq = 0;
    var jerkCount = 0;
    double? prevSpeed;
    for (var i = 0; i < displacements.length; i++) {
      final dt = max(_eps, samples[i + 1].t - samples[i].t);
      final speed = displacements[i].magnitude / dt;
      sum += speed;
      sumSq += speed * speed;
      if (prevSpeed != null) {
        final jerk = speed - prevSpeed;
        jerkSum += jerk;
        jerkSumSq += jerk * jerk;
        jerkCount += 1;
      }
      prevSpeed = speed;
    }
    final count = max(1, displacements.length);
    final mean = sum / count;
    final variance = (sumSq / count) - mean * mean;
    final std = sqrt(max(0.0, variance));
    final cv = std / (mean + _eps);

    double jerkStd = 0;
    if (jerkCount > 0) {
      final jerkMean = jerkSum / max(1, jerkCount);
      final jerkVar = (jerkSumSq / max(1, jerkCount)) - jerkMean * jerkMean;
      jerkStd = sqrt(max(0.0, jerkVar));
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

  static FrequencyResult _frequency(MotionMetricsCache cache) {
    if (cache.samples.length < 4 ||
        cache.principalAxis.magnitude < _eps ||
        cache.centeredSignal.isEmpty) {
      return const FrequencyResult(hertz: 0, confidence: 0);
    }

    final sampleRate = cache.sampleRate;
    final centered = cache.centeredSignal;
    final r0 = cache.signalEnergy;
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

  static Vector2 _directionFromAxis(
    Vector2 axis,
    List<Vector2> displacements,
  ) {
    if (axis.magnitude < _eps) {
      return const Vector2(0, 0);
    }
    if (displacements.isEmpty) {
      return axis.normalized();
    }
    final net = displacements.fold<Vector2>(
      const Vector2(0, 0),
      (s, d) => s + d,
    );
    if (net.magnitude < _eps) {
      return axis.normalized();
    }
    final aligned = net.dot(axis) < 0 ? axis.scale(-1) : axis;
    return aligned.normalized();
  }

  static double _intensity(
    double meanSpeed,
    double sampleRate,
    double spatialScale,
  ) {
    const scale = 0.05;
    final denom = spatialScale * sampleRate * scale + _eps;
    final score = 100 * (meanSpeed / denom);
    return score.clamp(0, 100);
  }

  static double _spatialScale(List<MotionSample> samples, Vector2 mean) {
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
    var obsIndex = 1;
    for (final t in target) {
      final interp = _interpolateSequential(observed, t.t, obsIndex);
      obsIndex = interp.nextIndex;
      final dx = interp.position.x - t.position.x;
      final dy = interp.position.y - t.position.y;
      mse += (dx * dx + dy * dy);
    }
    mse /= target.length;
    mse /= pow(max(_eps, expectedAmplitude), 2);

    final denom = tolerance * tolerance + _eps;
    final score = (1 / (1 + mse / denom) * 100).clamp(0.0, 100.0);
    return PatternMatchResult(score: score, mse: mse);
  }

  static _Interpolated _interpolateSequential(
    List<MotionSample> samples,
    double t,
    int startIndex,
  ) {
    if (t <= samples.first.t) {
      return _Interpolated(position: samples.first.position, nextIndex: 1);
    }
    if (t >= samples.last.t) {
      return _Interpolated(
        position: samples.last.position,
        nextIndex: samples.length - 1,
      );
    }

    var idx = startIndex.clamp(1, samples.length - 1);
    while (idx < samples.length && samples[idx].t < t) {
      idx++;
    }
    final a = samples[idx - 1];
    final b = samples[idx];
    final span = max(_eps, b.t - a.t);
    final alpha = (t - a.t) / span;
    return _Interpolated(
      position: Vector2(
        a.position.x + (b.position.x - a.position.x) * alpha,
        a.position.y + (b.position.y - a.position.y) * alpha,
      ),
      nextIndex: idx,
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

class _Interpolated {
  final Vector2 position;
  final int nextIndex;

  const _Interpolated({
    required this.position,
    required this.nextIndex,
  });
}
