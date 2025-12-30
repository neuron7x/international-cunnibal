import 'dart:math';

import 'package:international_cunnibal/models/metrics.dart';

class IncrementalStats {
  int _count = 0;
  double _mean = 0;
  double _m2 = 0;

  void update(double value) {
    _count++;
    final delta = value - _mean;
    _mean += delta / _count;
    final delta2 = value - _mean;
    _m2 += delta * delta2;
  }

  int get count => _count;
  double get mean => _mean;
  double get variance => _count > 1 ? _m2 / (_count - 1) : 0;
  double get stddev => sqrt(variance);

  void reset() {
    _count = 0;
    _mean = 0;
    _m2 = 0;
  }

  Map<String, dynamic> toMap() => {
        'count': _count,
        'mean': _mean,
        'm2': _m2,
      };

  static IncrementalStats fromMap(Map<String, dynamic> map) {
    final stats = IncrementalStats();
    stats._count = map['count'] as int;
    stats._mean = (map['mean'] as num).toDouble();
    stats._m2 = (map['m2'] as num).toDouble();
    return stats;
  }

  static IncrementalStats combine(
    IncrementalStats a,
    IncrementalStats b,
  ) {
    if (a._count == 0) return b;
    if (b._count == 0) return a;

    final result = IncrementalStats();
    result._count = a._count + b._count;
    final delta = b._mean - a._mean;
    result._mean = (a._mean * a._count + b._mean * b._count) / result._count;
    result._m2 = a._m2 +
        b._m2 +
        delta * delta * a._count * b._count / result._count;
    return result;
  }
}

class MetricsAggregator {
  final IncrementalStats consistencyStats;
  final IncrementalStats frequencyStats;
  final IncrementalStats enduranceStats;

  MetricsAggregator({
    IncrementalStats? consistencyStats,
    IncrementalStats? frequencyStats,
    IncrementalStats? enduranceStats,
  })  : consistencyStats = consistencyStats ?? IncrementalStats(),
        frequencyStats = frequencyStats ?? IncrementalStats(),
        enduranceStats = enduranceStats ?? IncrementalStats();

  void ingest(BiometricMetrics metrics) {
    consistencyStats.update(metrics.consistencyScore);
    frequencyStats.update(metrics.frequency);
    enduranceStats.update(metrics.endurance.enduranceScore);
  }

  void reset() {
    consistencyStats.reset();
    frequencyStats.reset();
    enduranceStats.reset();
  }

  MetricsAggregator combine(MetricsAggregator other) {
    return MetricsAggregator(
      consistencyStats:
          IncrementalStats.combine(consistencyStats, other.consistencyStats),
      frequencyStats:
          IncrementalStats.combine(frequencyStats, other.frequencyStats),
      enduranceStats:
          IncrementalStats.combine(enduranceStats, other.enduranceStats),
    );
  }

  Map<String, dynamic> summary() {
    return {
      'avgConsistency': consistencyStats.mean,
      'stdConsistency': consistencyStats.stddev,
      'avgFrequency': frequencyStats.mean,
      'stdFrequency': frequencyStats.stddev,
      'avgEnduranceScore': enduranceStats.mean,
      'stdEnduranceScore': enduranceStats.stddev,
      'totalMetrics': consistencyStats.count,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'consistency': consistencyStats.toMap(),
      'frequency': frequencyStats.toMap(),
      'endurance': enduranceStats.toMap(),
    };
  }

  static MetricsAggregator fromMap(Map<String, dynamic> map) {
    return MetricsAggregator(
      consistencyStats:
          IncrementalStats.fromMap(map['consistency'] as Map<String, dynamic>),
      frequencyStats:
          IncrementalStats.fromMap(map['frequency'] as Map<String, dynamic>),
      enduranceStats:
          IncrementalStats.fromMap(map['endurance'] as Map<String, dynamic>),
    );
  }
}
