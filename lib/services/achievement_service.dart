import 'package:flutter/material.dart';
import 'package:international_cunnibal/models/achievement.dart';

class AchievementService {
  final Map<String, Achievement> _achievements = {};

  AchievementService() {
    _bootstrapDefaults();
  }

  List<Achievement> allAchievements() =>
      _achievements.values.toList(growable: false);

  Achievement? unlock(String id) {
    final current = _achievements[id];
    if (current == null) return null;
    final updated = current.copyWith(
      unlocked: true,
      unlockedAt: DateTime.now(),
    );
    _achievements[id] = updated;
    return updated;
  }

  bool isUnlocked(String id) => _achievements[id]?.unlocked ?? false;

  void _bootstrapDefaults() {
    _achievements.addAll({
      'first_steps': Achievement(
        id: 'first_steps',
        name: 'First Steps',
        description: 'Complete 1 session',
        icon: Icons.directions_walk,
        tier: AchievementTier.bronze,
      ),
      'week_warrior': Achievement(
        id: 'week_warrior',
        name: 'Week Warrior',
        description: '7-day streak',
        icon: Icons.calendar_today,
        tier: AchievementTier.silver,
      ),
      'endurance_master': Achievement(
        id: 'endurance_master',
        name: 'Endurance Master',
        description: '60s hold @ 80% stability',
        icon: Icons.timer,
        tier: AchievementTier.gold,
      ),
      'rhythm_god': Achievement(
        id: 'rhythm_god',
        name: 'Rhythm God',
        description: '95% sync on 10 symbols',
        icon: Icons.music_note,
        tier: AchievementTier.gold,
      ),
      'social_butterfly': Achievement(
        id: 'social_butterfly',
        name: 'Social Butterfly',
        description: '10 partner sessions',
        icon: Icons.people,
        tier: AchievementTier.silver,
      ),
      'perfectionist': Achievement(
        id: 'perfectionist',
        name: 'Perfectionist',
        description: '100% on any challenge',
        icon: Icons.star,
        tier: AchievementTier.diamond,
      ),
      'influencer': Achievement(
        id: 'influencer',
        name: 'Influencer',
        description: 'Refer 5 friends',
        icon: Icons.campaign,
        tier: AchievementTier.gold,
      ),
    });
  }
}
