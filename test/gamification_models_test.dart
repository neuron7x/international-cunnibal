import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/achievement.dart';
import 'package:international_cunnibal/models/daily_challenge.dart';
import 'package:international_cunnibal/models/score.dart';

void main() {
  test('Score badge tiers derive from endurance score', () {
    final bronze = Score(
      userId: 'u1',
      enduranceScore: 40,
      streakDays: 2,
      totalSessions: 5,
      timestamp: DateTime.now(),
    );
    final diamond = Score(
      userId: 'u2',
      enduranceScore: 95,
      streakDays: 10,
      totalSessions: 25,
      timestamp: DateTime.now(),
    );

    expect(bronze.badge, AchievementTier.bronze);
    expect(diamond.badge, AchievementTier.diamond);
  });

  test('DailyChallenge supports serialization', () {
    final challenge = DailyChallenge(
      id: 'c1',
      title: 'Hold 40s endurance',
      description: 'Maintain stability for 40 seconds',
      type: ChallengeType.endurance,
      target: {'duration': 40, 'stability': 70},
      rewardPoints: 100,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );

    final json = challenge.toJson();
    final restored = DailyChallenge.fromJson(json);

    expect(restored.title, equals(challenge.title));
    expect(restored.type, equals(challenge.type));
    expect(restored.target['duration'], equals(40));
  });

  test('Achievement serializes icon metadata', () {
    final achievement = Achievement(
      id: 'a1',
      name: 'Test',
      description: 'Serialization check',
      icon: Icons.star,
      tier: AchievementTier.gold,
    );

    final json = achievement.toJson();
    final restored = Achievement.fromJson(json);

    expect(restored.name, equals(achievement.name));
    expect(restored.icon.codePoint, equals(achievement.icon.codePoint));
    expect(restored.tier, equals(achievement.tier));
  });

  test('Score.fromJson validates input ranges', () {
    expect(
      () => Score.fromJson({
        'userId': '',
        'enduranceScore': -1,
        'streakDays': 0,
        'totalSessions': 0,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
