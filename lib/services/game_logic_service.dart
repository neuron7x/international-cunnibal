import 'dart:async';
import 'package:international_cunnibal/models/game_state.dart';
import 'package:international_cunnibal/models/metrics.dart';

class GameLogicService {
  static final GameLogicService _instance = GameLogicService._internal();
  factory GameLogicService() => _instance;
  GameLogicService._internal();

  final StreamController<GameState> _stateController =
      StreamController<GameState>.broadcast();

  static const int _directionStabilityThreshold = 10;
  static const int _levelStreakThreshold = 3;
  static const int _consistencyReward = 10;
  static const int _frequencyReward = 5;
  static const int _directionReward = 3;
  static const double _consistencyStep = 5;
  static const double _consistencyMin = 60;
  static const double _consistencyMax = 95;
  static const double _frequencyStep = 0.1;
  static const double _frequencyMin = 1.0;
  static const double _frequencyMax = 3.0;

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
    final hitDirection = metrics.directionStability >= _directionStabilityThreshold;

    var score = _state.score;
    var streak = _state.streak;

    if (hitConsistency) score += _consistencyReward;
    if (hitFrequency) score += _frequencyReward;
    if (hitDirection) score += _directionReward;

    if (hitConsistency && hitFrequency) {
      streak += 1;
    } else {
      streak = 0;
    }

    var level = _state.level;
    var targetConsistency = _state.targetConsistency;
    var targetFrequency = _state.targetFrequency;

    if (streak >= _levelStreakThreshold) {
      level += 1;
      targetConsistency =
          (targetConsistency + _consistencyStep).clamp(_consistencyMin, _consistencyMax);
      targetFrequency =
          (targetFrequency + _frequencyStep).clamp(_frequencyMin, _frequencyMax);
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
