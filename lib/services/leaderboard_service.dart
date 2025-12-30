import 'dart:math';

import 'package:international_cunnibal/models/score.dart';

enum LeaderboardFilter { daily, weekly, allTime }

class LeaderboardService {
  final List<Score> _scores = [];
  final String? localUserId;
  static const int _seed = 42;

  LeaderboardService({this.localUserId}) {
    _seedIfEmpty();
  }

  Future<List<Score>> getTop100({
    LeaderboardFilter filter = LeaderboardFilter.allTime,
  }) async {
    final now = DateTime.now();
    final filtered = _scores
        .where((score) => _isWithinFilter(score.timestamp, filter, now))
        .toList()
      ..sort(
        (a, b) => b.totalPoints.compareTo(a.totalPoints),
      );
    return filtered.take(100).toList(growable: false);
  }

  Future<void> submitScore(Score score) async {
    final index = _scores.indexWhere((s) => s.userId == score.userId);
    if (index >= 0) {
      _scores[index] = score;
    } else {
      _scores.add(score);
    }
  }

  int rankOf(
    String userId, {
    LeaderboardFilter filter = LeaderboardFilter.allTime,
  }) {
    final now = DateTime.now();
    final sorted = _scores
        .where((score) => _isWithinFilter(score.timestamp, filter, now))
        .toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].userId == userId) {
        return i + 1;
      }
    }
    return -1;
  }

  Score? currentUserScore() {
    if (localUserId == null) return null;
    for (final score in _scores) {
      if (score.userId == localUserId) return score;
    }
    return null;
  }

  bool _isWithinFilter(
    DateTime timestamp,
    LeaderboardFilter filter,
    DateTime now,
  ) {
    switch (filter) {
      case LeaderboardFilter.daily:
        return now.difference(timestamp).inHours < 24;
      case LeaderboardFilter.weekly:
        return now.difference(timestamp).inDays < 7;
      case LeaderboardFilter.allTime:
        return true;
    }
  }

  void _seedIfEmpty() {
    if (_scores.isNotEmpty) return;
    final random = Random(_seed);
    final now = DateTime.now();
    for (var i = 0; i < 12; i++) {
      _scores.add(
        Score(
          userId: 'user-$i',
          enduranceScore: 40 + random.nextInt(60),
          streakDays: 1 + random.nextInt(14),
          totalSessions: 5 + random.nextInt(30),
          timestamp: now.subtract(Duration(hours: random.nextInt(96))),
          displayName: 'User #$i',
        ),
      );
    }
    if (localUserId != null) {
      _scores.add(
        Score(
          userId: localUserId!,
          enduranceScore: 80,
          streakDays: 5,
          totalSessions: 18,
          timestamp: now,
          displayName: 'You',
        ),
      );
    }
  }
}
