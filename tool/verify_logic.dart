import 'package:international_cunnibal/core/motion_metrics.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:international_cunnibal/services/game_logic_service.dart';

Future<void> main() async {
  final game = GameLogicService();

  final buffer = List.generate(20, (i) {
    final t = i * 0.05;
    final position = Vector2(0.3 + i * 0.02, 0.4 + i * 0.005);
    return MotionSample(t: t, position: position);
  });

  final motion = MotionMetrics.compute(
    samples: buffer,
    expectedAmplitude: 0.5,
  );

  final metrics = BiometricMetrics(
    consistencyScore: motion.consistency,
    frequency: motion.frequency.hertz,
    frequencyConfidence: motion.frequency.confidence,
    pcaVariance: const [0, 0, 0],
    movementDirection: _toDirection(motion.direction.direction),
    directionStability: motion.direction.stability,
    intensity: motion.intensity,
    patternScore: motion.patternMatch.score,
    timestamp: DateTime.now(),
  );

  game.ingest(metrics);

  // ignore: avoid_print
  print('Direction: ${metrics.movementDirection.label}');
  // ignore: avoid_print
  print('Game state -> Level: ${game.state.level}, Score: ${game.state.score}');

  if (metrics.movementDirection == MovementDirection.steady) {
    throw StateError('Movement direction should not be steady for diagonal move');
  }
}

MovementDirection _toDirection(Vector2 v) {
  if (v.magnitude < 1e-6) return MovementDirection.steady;
  if (v.x.abs() >= v.y.abs()) {
    return v.x >= 0 ? MovementDirection.right : MovementDirection.left;
  }
  return v.y >= 0 ? MovementDirection.down : MovementDirection.up;
}
