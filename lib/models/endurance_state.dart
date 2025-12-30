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

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'badges': badges,
      'targetAperture': targetAperture,
      'targetStability': targetStability,
      'targetTime': targetTime,
      'streak': streak,
    };
  }

  factory EnduranceState.fromJson(Map<String, dynamic> json) {
    return EnduranceState(
      level: json['level'] as int,
      badges: json['badges'] as int,
      targetAperture: (json['targetAperture'] as num).toDouble(),
      targetStability: (json['targetStability'] as num).toDouble(),
      targetTime: (json['targetTime'] as num).toDouble(),
      streak: json['streak'] as int,
    );
  }
}
