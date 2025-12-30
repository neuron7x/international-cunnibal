import 'dart:math';

import 'package:international_cunnibal/models/daily_challenge.dart';

class DailyChallengeService {
  final Map<String, List<DailyChallenge>> _cache = {};
  final Random _random = Random();

  Future<List<DailyChallenge>> getTodayChallenges() async {
    final key = _keyFor(DateTime.now());
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    final generated = _generateChallenges();
    _cache[key] = generated;
    return generated;
  }

  void resetCache() => _cache.clear();

  String _keyFor(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  List<DailyChallenge> _generateChallenges() {
    final now = DateTime.now();
    final expiresAt = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final templates = <DailyChallenge>[
      DailyChallenge(
        id: 'endurance-${now.toIso8601String()}',
        title: 'Hold 40s endurance',
        description: 'Maintain stability for 40 seconds',
        type: ChallengeType.endurance,
        target: {'duration': 40, 'stability': 70},
        rewardPoints: 100,
        expiresAt: expiresAt,
      ),
      DailyChallenge(
        id: 'rhythm-${now.toIso8601String()}',
        title: 'Rhythm sync',
        description: 'Complete 5 symbols with 80% sync',
        type: ChallengeType.rhythm,
        target: {'symbols': 5, 'sync': 80},
        rewardPoints: 75,
        expiresAt: expiresAt,
      ),
      DailyChallenge(
        id: 'partner-${now.toIso8601String()}',
        title: 'Partner match',
        description: 'Partner session with 75% match',
        type: ChallengeType.partner,
        target: {'match': 75},
        rewardPoints: 90,
        expiresAt: expiresAt,
      ),
      DailyChallenge(
        id: 'streak-${now.toIso8601String()}',
        title: 'Three-day streak',
        description: 'Train 3 days in a row',
        type: ChallengeType.streak,
        target: {'days': 3},
        rewardPoints: 60,
        expiresAt: expiresAt,
      ),
    ];

    templates.shuffle(_random);
    return templates.take(3).toList(growable: false);
  }
}
