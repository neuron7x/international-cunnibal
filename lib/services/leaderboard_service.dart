import 'dart:math';

import 'package:international_cunnibal/models/score.dart';
import 'package:international_cunnibal/services/backend/leaderboard_backend.dart';

enum LeaderboardFilter { daily, weekly, allTime }

class LeaderboardService {
  final List<Score> _scores = [];
  final String? localUserId;
  static const int _seed = 42;
  static const Duration _minSubmitInterval = Duration(minutes: 5);
  final DateTime Function() _clock;
  final LeaderboardBackend _backend;
  DateTime? _lastSubmit;

  LeaderboardService({
    this.localUserId,
    DateTime Function()? clock,
    LeaderboardBackend? backend,
  })  : _clock = clock ?? DateTime.now,
        _backend = backend ?? InMemoryLeaderboardBackend([]) {
    _seedIfEmpty();
  }

  Future<List<Score>> getTop100({
    LeaderboardFilter filter = LeaderboardFilter.allTime,
  }) async {
    return _backend.getTop(filter: filter, limit: 100);
  }

  Future<void> submitScore(Score score) async {
    score.ensureValid();
    final now = _clock();
    if (_lastSubmit != null &&
        now.difference(_lastSubmit!) < _minSubmitInterval) {
      throw Exception(
        'Rate limit: wait ${_minSubmitInterval.inMinutes} minutes between submissions',
      );
    }
    await _backend.upsertScore(score);
    final index = _scores.indexWhere((s) => s.userId == score.userId);
    if (index >= 0) {
      _scores[index] = score;
    } else {
      _scores.add(score);
    }
    _lastSubmit = now;
  }

  int rankOf(
    String userId, {
    LeaderboardFilter filter = LeaderboardFilter.allTime,
  }) {
    final now = _clock();
    final sorted = _scores
        .where((score) => isWithinFilter(score.timestamp, filter, now))
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

  static bool isWithinFilter(
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
    final now = _clock();
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
    // keep backend in sync
    for (final score in _scores) {
      _backend.upsertScore(score);
    }
  }
}
