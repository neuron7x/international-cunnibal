import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/services/game_logic_service.dart';
import 'package:international_cunnibal/services/signal_processor.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  final processor = SignalProcessor();
  final game = GameLogicService();
  final now = DateTime.now();

  final buffer = List.generate(20, (i) {
    final position = Offset(0.3 + i * 0.02, 0.4 + i * 0.005);
    return TongueData(
      timestamp: now.add(Duration(milliseconds: i * 50)),
      position: position,
      velocity: 1.5,
      acceleration: 0.1,
      landmarks: const [Offset(0.5, 0.5)],
      isValidated: true,
    );
  });

  final metrics = processor.calculate(buffer);
  game.ingest(metrics);

  // ignore: avoid_print
  print('Direction: ${metrics.movementDirection.label}');
  // ignore: avoid_print
  print('Game state -> Level: ${game.state.level}, Score: ${game.state.score}');

  if (metrics.movementDirection == MovementDirection.steady) {
    throw StateError('Movement direction should not be steady for diagonal move');
  }
}
