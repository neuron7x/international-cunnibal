import 'package:international_cunnibal/models/achievement.dart';

class Score {
  final String userId;
  final int enduranceScore;
  final int streakDays;
  final int totalSessions;
  final DateTime timestamp;
  final String? displayName;

  const Score({
    required this.userId,
    required this.enduranceScore,
    required this.streakDays,
    required this.totalSessions,
    required this.timestamp,
    this.displayName,
  });

  int get totalPoints => enduranceScore + (streakDays * 2) + totalSessions;

  AchievementTier get badge {
    if (enduranceScore >= 90) return AchievementTier.diamond;
    if (enduranceScore >= 75) return AchievementTier.gold;
    if (enduranceScore >= 50) return AchievementTier.silver;
    return AchievementTier.bronze;
  }

  Score copyWith({
    int? enduranceScore,
    int? streakDays,
    int? totalSessions,
    DateTime? timestamp,
    String? displayName,
  }) {
    return Score(
      userId: userId,
      enduranceScore: enduranceScore ?? this.enduranceScore,
      streakDays: streakDays ?? this.streakDays,
      totalSessions: totalSessions ?? this.totalSessions,
      timestamp: timestamp ?? this.timestamp,
      displayName: displayName ?? this.displayName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'enduranceScore': enduranceScore,
      'streakDays': streakDays,
      'totalSessions': totalSessions,
      'timestamp': timestamp.toIso8601String(),
      'displayName': displayName,
      'badge': badge.name,
    };
  }

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      userId: json['userId'] as String,
      enduranceScore: json['enduranceScore'] as int,
      streakDays: json['streakDays'] as int,
      totalSessions: json['totalSessions'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      displayName: json['displayName'] as String?,
    );
  }
}
