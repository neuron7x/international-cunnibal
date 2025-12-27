import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:international_cunnibal/services/game_logic_service.dart';

void main() {
  group('GameLogicService', () {
    final game = GameLogicService();

    setUp(() {
      game.reset();
    });

    BiometricMetrics _goodMetrics() {
      return BiometricMetrics(
        consistencyScore: 90,
        frequency: 2.0,
        pcaVariance: const [50, 30, 20],
        movementDirection: MovementDirection.right,
        directionStability: 40,
        timestamp: DateTime.now(),
      );
    }

    test('increments score on good metrics', () {
      final initialScore = game.state.score;
      game.ingest(_goodMetrics());

      expect(game.state.score, greaterThan(initialScore));
    });

    test('levels up after streak', () {
      final initialLevel = game.state.level;
      for (int i = 0; i < 3; i++) {
        game.ingest(_goodMetrics());
      }

      expect(game.state.level, greaterThan(initialLevel));
    });
  });
}
