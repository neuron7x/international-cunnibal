import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:international_cunnibal/services/game_logic_service.dart';

void main() {
  group('GameLogicService', () {
    final game = GameLogicService();

    setUp(() {
      game.reset();
    });

    BiometricMetrics goodMetrics() {
      return BiometricMetrics(
        consistencyScore: 90,
        frequency: 2.0,
        frequencyConfidence: 0.9,
        pcaVariance: const [50, 30, 20],
        movementDirection: MovementDirection.right,
        directionStability: 40,
        intensity: 60,
        patternScore: 80,
        endurance: const EnduranceSnapshot(
          aperture: 0.25,
          apertureStability: 70,
          fatigueIndicator: 5,
          enduranceTime: 2,
          enduranceScore: 75,
          threshold: 0.18,
        ),
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }

    test('increments score on good metrics', () {
      final initialScore = game.state.score;
      game.ingest(goodMetrics());

      expect(game.state.score, greaterThan(initialScore));
    });

    test('levels up after streak', () {
      final initialLevel = game.state.level;
      for (int i = 0; i < 3; i++) {
        game.ingest(goodMetrics());
      }

      expect(game.state.level, greaterThan(initialLevel));
      expect(game.state.streak, equals(0));
    });

    test('direction stability gating', () {
      final baseline = game.state.score;
      final base = goodMetrics();
      final lowDirection = BiometricMetrics(
        consistencyScore: base.consistencyScore,
        frequency: base.frequency,
        frequencyConfidence: base.frequencyConfidence,
        pcaVariance: base.pcaVariance,
        movementDirection: base.movementDirection,
        directionStability: 5,
        intensity: base.intensity,
        patternScore: base.patternScore,
        endurance: base.endurance,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      );
      game.ingest(lowDirection);
      expect(
        game.state.score,
        equals(baseline + 15),
      ); // consistency+frequency only
    });

    test('low metrics do not level up', () {
      for (int i = 0; i < 5; i++) {
        game.ingest(
          BiometricMetrics(
            consistencyScore: 10,
            frequency: 0.5,
            frequencyConfidence: 0.2,
            pcaVariance: const [0, 0, 0],
            movementDirection: MovementDirection.right,
            directionStability: 50,
            intensity: 5,
            patternScore: 0,
            endurance: EnduranceSnapshot.empty(),
            timestamp: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
      }
      expect(game.state.level, equals(1));
    });

    test('threshold boundaries count as hits', () {
      final metrics = BiometricMetrics(
        consistencyScore: game.state.targetConsistency,
        frequency: game.state.targetFrequency,
        frequencyConfidence: 0.9,
        pcaVariance: const [50, 30, 20],
        movementDirection: MovementDirection.right,
        directionStability: 10,
        intensity: 60,
        patternScore: 80,
        endurance: const EnduranceSnapshot(
          aperture: 0.25,
          apertureStability: 70,
          fatigueIndicator: 5,
          enduranceTime: 2,
          enduranceScore: 75,
          threshold: 0.18,
        ),
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      );

      game.ingest(metrics);
      expect(game.state.streak, equals(1));
    });
  });
}
