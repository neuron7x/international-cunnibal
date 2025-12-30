import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:international_cunnibal/services/analytics/incremental_stats.dart';

void main() {
  group('IncrementalStats', () {
    test('computes mean and variance incrementally', () {
      final stats = IncrementalStats();
      stats.update(2);
      stats.update(4);
      stats.update(6);

      expect(stats.count, 3);
      expect(stats.mean, closeTo(4, 1e-6));
      expect(stats.variance, closeTo(4, 1e-6));
    });
  });

  group('MetricsAggregator', () {
    test('aggregates metrics incrementally', () {
      final aggregator = MetricsAggregator();
      aggregator.ingest(
        BiometricMetrics(
          consistencyScore: 50,
          frequency: 2.0,
          frequencyConfidence: 0.8,
          pcaVariance: const [0.4, 0.3, 0.3],
          movementDirection: MovementDirection.up,
          directionStability: 50,
          intensity: 50,
          patternScore: 50,
          endurance: EnduranceSnapshot.empty(),
          timestamp: DateTime(2025, 12, 26),
        ),
      );
      aggregator.ingest(
        BiometricMetrics(
          consistencyScore: 70,
          frequency: 4.0,
          frequencyConfidence: 0.9,
          pcaVariance: const [0.5, 0.3, 0.2],
          movementDirection: MovementDirection.down,
          directionStability: 60,
          intensity: 55,
          patternScore: 60,
          endurance: EnduranceSnapshot.empty(),
          timestamp: DateTime(2025, 12, 27),
        ),
      );

      final summary = aggregator.summary();

      expect(summary['avgConsistency'], closeTo(60, 1e-6));
      expect(summary['avgFrequency'], closeTo(3, 1e-6));
      expect(summary['avgEnduranceScore'], closeTo(0, 1e-6));
      expect(summary['totalMetrics'], 2);
    });
  });
}
