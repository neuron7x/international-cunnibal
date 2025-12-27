class EnduranceState {
  final int level;
  final int badges;
  final double targetAperture;
  final double targetStability;
  final double targetTime;
  final int streak;

  const EnduranceState({
    required this.level,
    required this.badges,
    required this.targetAperture,
    required this.targetStability,
    required this.targetTime,
    required this.streak,
  });

  EnduranceState copyWith({
    int? level,
    int? badges,
    double? targetAperture,
    double? targetStability,
    double? targetTime,
    int? streak,
  }) {
    return EnduranceState(
      level: level ?? this.level,
      badges: badges ?? this.badges,
      targetAperture: targetAperture ?? this.targetAperture,
      targetStability: targetStability ?? this.targetStability,
      targetTime: targetTime ?? this.targetTime,
      streak: streak ?? this.streak,
    );
  }
}
