import 'package:international_cunnibal/models/endurance_session_state.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/utils/constants.dart';

class EnduranceSessionService {
  EnduranceSessionState _state = EnduranceSessionState.initial(
    targetHoldSeconds: EnduranceConstants.targetHoldSeconds,
  );

  double? _sessionStart;
  double? _phaseStart;
  double? _lastUpdate;
  double? _cooldownUntil;
  double? _lastStability;
  bool _cooldownApplied = false;

  EnduranceSessionState get state => _state;

  void start(double tSeconds) {
    if (_cooldownUntil != null && tSeconds < _cooldownUntil!) {
      final remaining = (_cooldownUntil! - tSeconds).clamp(0.0, 9999);
      _state = _state.copyWith(
        canStart: false,
        prompt: 'Cooldown active. Please rest before the next session.',
        cooldownRemainingSeconds: remaining,
      );
      return;
    }
    _sessionStart = tSeconds;
    _phaseStart = tSeconds;
    _lastUpdate = tSeconds;
    _lastStability = null;
    _cooldownApplied = false;
    _state = EnduranceSessionState(
      phase: EnduranceSessionPhase.ready,
      sessionSeconds: 0,
      phaseSeconds: 0,
      safeHoldSeconds: 0,
      targetHoldSeconds: EnduranceConstants.targetHoldSeconds,
      cooldownRemainingSeconds: 0,
      autoPaused: false,
      prompt: 'Get comfortable. We will start shortly.',
      canStart: true,
    );
  }

  void stop(double tSeconds) {
    _phaseStart = tSeconds;
    _lastUpdate = tSeconds;
    _applyCooldown(tSeconds);
    final remaining = _cooldownUntil == null
        ? 0.0
        : (_cooldownUntil! - tSeconds).clamp(0.0, 9999);
    _state = _state.copyWith(
      phase: EnduranceSessionPhase.summary,
      cooldownRemainingSeconds: remaining,
      canStart: remaining <= 0,
      prompt: 'Session stopped. Take a rest if you need.',
    );
  }

  EnduranceSessionState ingest({
    required EnduranceSnapshot snapshot,
    required double tSeconds,
  }) {
    if (_sessionStart == null || _phaseStart == null) {
      start(tSeconds);
    }

    final sessionSeconds = tSeconds - (_sessionStart ?? tSeconds);
    final phaseSeconds = tSeconds - (_phaseStart ?? tSeconds);
    final dt = _lastUpdate == null ? 0.0 : (tSeconds - _lastUpdate!).clamp(0.0, 1);
    _lastUpdate = tSeconds;

    var cooldownRemaining = _cooldownUntil == null
        ? 0.0
        : (_cooldownUntil! - tSeconds).clamp(0.0, double.infinity);
    var canStart = cooldownRemaining <= 0;

    var phase = _state.phase;
    var prompt = _state.prompt;
    var safeHold = _state.safeHoldSeconds;
    var autoPaused = _state.autoPaused;

    final apertureInBounds =
        snapshot.aperture >= EnduranceConstants.apertureSafetyMin &&
            snapshot.aperture <= EnduranceConstants.apertureSafetyMax;
    final stabilityOk = snapshot.apertureStability >= EnduranceConstants.stabilityFloor;

    if (phase == EnduranceSessionPhase.ready &&
        phaseSeconds >= EnduranceConstants.readySeconds) {
      phase = EnduranceSessionPhase.hold;
      _phaseStart = tSeconds;
      prompt = 'Hold steady. Focus on control and comfort.';
    }

    if (phase == EnduranceSessionPhase.hold) {
      if (sessionSeconds >= EnduranceConstants.maxSessionSeconds) {
        phase = EnduranceSessionPhase.summary;
        prompt = 'Session complete. Maximum duration reached.';
      } else if (snapshot.fatigueIndicator >= EnduranceConstants.fatigueStopThreshold) {
        phase = EnduranceSessionPhase.summary;
        prompt = 'Session complete. Fatigue threshold reached.';
      } else if (!apertureInBounds || !stabilityOk) {
        autoPaused = true;
        phase = EnduranceSessionPhase.rest;
        prompt = 'Rest for comfort. Resume when stability returns.';
        _phaseStart = tSeconds;
      } else if (_lastStability != null &&
          (_lastStability! - snapshot.apertureStability) >=
              EnduranceConstants.stabilityDropThreshold) {
        autoPaused = true;
        phase = EnduranceSessionPhase.rest;
        prompt = 'Stability dipped. Take a rest and reset.';
        _phaseStart = tSeconds;
      } else {
        safeHold += dt;
        prompt = 'Hold steady. Smooth, controlled aperture.';
        if (safeHold >= EnduranceConstants.targetHoldSeconds) {
          phase = EnduranceSessionPhase.rest;
          prompt = 'Great control. Begin your rest.';
          _phaseStart = tSeconds;
          autoPaused = false;
        }
      }
    }

    if (phase == EnduranceSessionPhase.rest) {
      if (phaseSeconds >= EnduranceConstants.restSeconds) {
        phase = EnduranceSessionPhase.summary;
        prompt = 'Session summary ready.';
      } else {
        prompt = autoPaused
            ? 'Auto-paused for stability. Rest gently.'
            : 'Rest and reset. We will summarize soon.';
      }
    }

    if (phase == EnduranceSessionPhase.summary) {
      _applyCooldown(tSeconds);
      cooldownRemaining = _cooldownUntil == null
          ? 0.0
          : (_cooldownUntil! - tSeconds).clamp(0.0, double.infinity);
      canStart = cooldownRemaining <= 0;
    }

    _lastStability = snapshot.apertureStability;

    _state = _state.copyWith(
      phase: phase,
      sessionSeconds: sessionSeconds.clamp(0.0, 9999),
      phaseSeconds: (tSeconds - (_phaseStart ?? tSeconds)).clamp(0.0, 9999),
      safeHoldSeconds: safeHold.clamp(0.0, EnduranceConstants.maxSessionSeconds),
      targetHoldSeconds: EnduranceConstants.targetHoldSeconds,
      cooldownRemainingSeconds: cooldownRemaining,
      autoPaused: autoPaused,
      prompt: prompt,
      canStart: canStart,
    );

    return _state;
  }

  void reset() {
    _sessionStart = null;
    _phaseStart = null;
    _lastUpdate = null;
    _lastStability = null;
    _cooldownApplied = false;
    _state = EnduranceSessionState.initial(
      targetHoldSeconds: EnduranceConstants.targetHoldSeconds,
    );
  }

  void _applyCooldown(double tSeconds) {
    if (_cooldownApplied) return;
    _cooldownUntil = tSeconds + EnduranceConstants.cooldownSeconds;
    _cooldownApplied = true;
  }
}
