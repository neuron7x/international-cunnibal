class GameState {
  final int level;
  final int score;
  final double targetConsistency;
  final double targetFrequency;
  final int streak;

  const GameState({
    required this.level,
    required this.score,
    required this.targetConsistency,
    required this.targetFrequency,
    required this.streak,
  });

  GameState copyWith({
    int? level,
    int? score,
    double? targetConsistency,
    double? targetFrequency,
    int? streak,
  }) {
    return GameState(
      level: level ?? this.level,
      score: score ?? this.score,
      targetConsistency: targetConsistency ?? this.targetConsistency,
      targetFrequency: targetFrequency ?? this.targetFrequency,
      streak: streak ?? this.streak,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'score': score,
      'targetConsistency': targetConsistency,
      'targetFrequency': targetFrequency,
      'streak': streak,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      level: json['level'] as int,
      score: json['score'] as int,
      targetConsistency: (json['targetConsistency'] as num).toDouble(),
      targetFrequency: (json['targetFrequency'] as num).toDouble(),
      streak: json['streak'] as int,
    );
  }
}
