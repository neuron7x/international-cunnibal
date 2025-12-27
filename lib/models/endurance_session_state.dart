enum EnduranceSessionPhase {
  ready,
  hold,
  rest,
  summary,
}

class EnduranceSessionState {
  final EnduranceSessionPhase phase;
  final double sessionSeconds;
  final double phaseSeconds;
  final double safeHoldSeconds;
  final double targetHoldSeconds;
  final double cooldownRemainingSeconds;
  final bool autoPaused;
  final String prompt;
  final bool canStart;

  const EnduranceSessionState({
    required this.phase,
    required this.sessionSeconds,
    required this.phaseSeconds,
    required this.safeHoldSeconds,
    required this.targetHoldSeconds,
    required this.cooldownRemainingSeconds,
    required this.autoPaused,
    required this.prompt,
    required this.canStart,
  });

  factory EnduranceSessionState.initial({
    double targetHoldSeconds = 0,
  }) {
    return EnduranceSessionState(
      phase: EnduranceSessionPhase.ready,
      sessionSeconds: 0,
      phaseSeconds: 0,
      safeHoldSeconds: 0,
      targetHoldSeconds: targetHoldSeconds,
      cooldownRemainingSeconds: 0,
      autoPaused: false,
      prompt: 'Ready when you are.',
      canStart: true,
    );
  }

  EnduranceSessionState copyWith({
    EnduranceSessionPhase? phase,
    double? sessionSeconds,
    double? phaseSeconds,
    double? safeHoldSeconds,
    double? targetHoldSeconds,
    double? cooldownRemainingSeconds,
    bool? autoPaused,
    String? prompt,
    bool? canStart,
  }) {
    return EnduranceSessionState(
      phase: phase ?? this.phase,
      sessionSeconds: sessionSeconds ?? this.sessionSeconds,
      phaseSeconds: phaseSeconds ?? this.phaseSeconds,
      safeHoldSeconds: safeHoldSeconds ?? this.safeHoldSeconds,
      targetHoldSeconds: targetHoldSeconds ?? this.targetHoldSeconds,
      cooldownRemainingSeconds:
          cooldownRemainingSeconds ?? this.cooldownRemainingSeconds,
      autoPaused: autoPaused ?? this.autoPaused,
      prompt: prompt ?? this.prompt,
      canStart: canStart ?? this.canStart,
    );
  }
}
