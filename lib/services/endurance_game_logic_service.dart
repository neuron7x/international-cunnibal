import 'dart:async';

import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/models/endurance_state.dart';
import 'package:international_cunnibal/utils/constants.dart';

class EnduranceGameLogicService {
  static final EnduranceGameLogicService _instance =
      EnduranceGameLogicService._internal();
  factory EnduranceGameLogicService() => _instance;
  EnduranceGameLogicService._internal();

  final StreamController<EnduranceState> _stateController =
      StreamController<EnduranceState>.broadcast();

  static const int _streakThreshold = 2;

  EnduranceState _state = const EnduranceState(
    level: 1,
    badges: 0,
    targetAperture: EnduranceConstants.defaultApertureThreshold,
    targetStability: EnduranceConstants.stabilityFloor,
    targetTime: EnduranceConstants.targetHoldSeconds,
    streak: 0,
  );

  Stream<EnduranceState> get stateStream => _stateController.stream;
  EnduranceState get state => _state;

  void ingest(EnduranceSnapshot snapshot) {
    final hitAperture = snapshot.aperture >= _state.targetAperture;
    final hitStability = snapshot.apertureStability >= _state.targetStability;
    final hitTime = snapshot.enduranceTime >= _state.targetTime;

    var badges = _state.badges;
    var streak = _state.streak;
    var level = _state.level;
    var targetAperture = _state.targetAperture;
    var targetStability = _state.targetStability;
    var targetTime = _state.targetTime;

    if (hitAperture && hitStability && hitTime) {
      badges += 1;
      streak += 1;
    } else {
      streak = 0;
    }

    if (streak >= _streakThreshold) {
      level += 1;
      targetAperture = (targetAperture + EnduranceConstants.apertureStep).clamp(
        EnduranceConstants.defaultApertureThreshold,
        0.6,
      );
      targetStability = (targetStability + EnduranceConstants.stabilityStep)
          .clamp(EnduranceConstants.stabilityFloor, 100);
      targetTime = (targetTime + EnduranceConstants.timeStep).clamp(
        EnduranceConstants.targetHoldSeconds,
        10,
      );
      streak = 0;
    }

    _state = _state.copyWith(
      level: level,
      badges: badges,
      targetAperture: targetAperture,
      targetStability: targetStability,
      targetTime: targetTime,
      streak: streak,
    );

    _stateController.add(_state);
  }

  void reset() {
    _state = const EnduranceState(
      level: 1,
      badges: 0,
      targetAperture: EnduranceConstants.defaultApertureThreshold,
      targetStability: EnduranceConstants.stabilityFloor,
      targetTime: EnduranceConstants.targetHoldSeconds,
      streak: 0,
    );
  }
}
