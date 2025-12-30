import 'package:international_cunnibal/models/score.dart';
import 'package:international_cunnibal/services/leaderboard_service.dart';

abstract class LeaderboardBackend {
  Future<List<Score>> getTop({
    required LeaderboardFilter filter,
    int limit,
  });

  Future<void> upsertScore(Score score);
}

class InMemoryLeaderboardBackend implements LeaderboardBackend {
  final List<Score> _scores;

  InMemoryLeaderboardBackend(this._scores);

  @override
  Future<List<Score>> getTop({
    required LeaderboardFilter filter,
    int limit = 100,
  }) async {
    final now = DateTime.now();
    final filtered = _scores
        .where((score) => LeaderboardService.isWithinFilter(
              score.timestamp,
              filter,
              now,
            ))
        .toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return filtered.take(limit).toList(growable: false);
  }

  @override
  Future<void> upsertScore(Score score) async {
    final index = _scores.indexWhere((s) => s.userId == score.userId);
    if (index >= 0) {
      _scores[index] = score;
    } else {
      _scores.add(score);
    }
  }
}
