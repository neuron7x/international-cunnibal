import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:international_cunnibal/validators/metrics_validator.dart';

void main() {
  group('MetricsValidator', () {
    test('returns no errors for valid metrics', () {
      final metrics = BiometricMetrics(
        consistencyScore: 80,
        frequency: 2.0,
        frequencyConfidence: 0.9,
        pcaVariance: const [0.4, 0.35, 0.25],
        movementDirection: MovementDirection.right,
        directionStability: 50,
        intensity: 60,
        patternScore: 70,
        endurance: EnduranceSnapshot.empty(),
        timestamp: DateTime(2025, 12, 26),
      );

      final errors = MetricsValidator.validate(metrics);

      expect(errors, isEmpty);
    });

    test('detects invalid metrics values', () {
      final metrics = BiometricMetrics(
        consistencyScore: -5,
        frequency: -1,
        frequencyConfidence: 1.5,
        pcaVariance: const [1.5, -0.1, -0.4],
        movementDirection: MovementDirection.left,
        directionStability: 10,
        intensity: 10,
        patternScore: 10,
        endurance: EnduranceSnapshot.empty(),
        timestamp: DateTime(2024, 12, 31),
      );

      final errors = MetricsValidator.validate(metrics);

      expect(errors, isNotEmpty);
    });
  });
}
