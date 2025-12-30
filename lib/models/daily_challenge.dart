enum ChallengeType {
  endurance,
  rhythm,
  partner,
  streak,
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final Map<String, dynamic> target;
  final int rewardPoints;
  final DateTime expiresAt;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.rewardPoints,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  DailyChallenge copyWith({
    String? title,
    String? description,
    ChallengeType? type,
    Map<String, dynamic>? target,
    int? rewardPoints,
    DateTime? expiresAt,
  }) {
    return DailyChallenge(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      target: target ?? this.target,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'target': target,
      'rewardPoints': rewardPoints,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ChallengeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ChallengeType.endurance,
      ),
      target: Map<String, dynamic>.from(json['target'] as Map),
      rewardPoints: json['rewardPoints'] as int,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
