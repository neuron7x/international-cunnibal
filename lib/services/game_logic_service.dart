import 'dart:async';
import 'package:international_cunnibal/models/game_state.dart';
import 'package:international_cunnibal/models/metrics.dart';

class GameLogicService {
  static final GameLogicService _instance = GameLogicService._internal();
  factory GameLogicService() => _instance;
  GameLogicService._internal();

  final StreamController<GameState> _stateController =
      StreamController<GameState>.broadcast();

  GameState _state = const GameState(
    level: 1,
    score: 0,
    targetConsistency: 60,
    targetFrequency: 1.0,
    streak: 0,
  );

  Stream<GameState> get stateStream => _stateController.stream;
  GameState get state => _state;

  void ingest(BiometricMetrics metrics) {
    final hitConsistency = metrics.consistencyScore >= _state.targetConsistency;
    final hitFrequency = metrics.frequency >= _state.targetFrequency;
    final hitDirection = metrics.directionStability >= 10;

    var score = _state.score;
    var streak = _state.streak;

    if (hitConsistency) score += 10;
    if (hitFrequency) score += 5;
    if (hitDirection) score += 3;

    if (hitConsistency && hitFrequency) {
      streak += 1;
    } else {
      streak = 0;
    }

    var level = _state.level;
    var targetConsistency = _state.targetConsistency;
    var targetFrequency = _state.targetFrequency;

    if (streak >= 3) {
      level += 1;
      targetConsistency = (targetConsistency + 5).clamp(60, 95);
      targetFrequency = (targetFrequency + 0.1).clamp(1.0, 3.0);
      streak = 0;
    }

    _state = _state.copyWith(
      level: level,
      score: score,
      targetConsistency: targetConsistency,
      targetFrequency: targetFrequency,
      streak: streak,
    );

    _stateController.add(_state);
  }

  void reset() {
    _state = const GameState(
      level: 1,
      score: 0,
      targetConsistency: 60,
      targetFrequency: 1.0,
      streak: 0,
    );
  }
}
