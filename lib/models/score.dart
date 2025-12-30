import 'package:international_cunnibal/models/achievement.dart';

class BadgeThresholds {
  static const int diamond = 90;
  static const int gold = 75;
  static const int silver = 50;
  static const int bronze = 0;
}

class Score {
  static const int maxStreakDays = 3650;
  static const int maxUserIdLength = 36;
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
    if (enduranceScore >= BadgeThresholds.diamond) {
      return AchievementTier.diamond;
    }
    if (enduranceScore >= BadgeThresholds.gold) return AchievementTier.gold;
    if (enduranceScore >= BadgeThresholds.silver) {
      return AchievementTier.silver;
    }
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
    final enduranceScore = json['enduranceScore'] as int;
    final streakDays = json['streakDays'] as int;
    final totalSessions = json['totalSessions'] as int;
    final userId = json['userId'] as String;

    _validate(
      userId: userId,
      enduranceScore: enduranceScore,
      streakDays: streakDays,
      totalSessions: totalSessions,
    );

    return Score(
      userId: userId,
      enduranceScore: enduranceScore,
      streakDays: streakDays,
      totalSessions: totalSessions,
      timestamp: DateTime.parse(json['timestamp'] as String),
      displayName: json['displayName'] as String?,
    );
  }

  void ensureValid() => _validate(
        userId: userId,
        enduranceScore: enduranceScore,
        streakDays: streakDays,
        totalSessions: totalSessions,
      );

  static void _validate({
    required String userId,
    required int enduranceScore,
    required int streakDays,
    required int totalSessions,
  }) {
    if (enduranceScore < 0 || enduranceScore > 100) {
      throw FormatException('Invalid enduranceScore: $enduranceScore');
    }
    if (streakDays < 0 || streakDays > Score.maxStreakDays) {
      throw FormatException('Invalid streakDays: $streakDays');
    }
    if (totalSessions < 0) {
      throw FormatException('Invalid totalSessions: $totalSessions');
    }
    if (userId.isEmpty || userId.length > Score.maxUserIdLength) {
      throw FormatException('Invalid userId');
    }
  }
}
