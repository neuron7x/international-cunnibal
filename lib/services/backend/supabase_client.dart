import 'package:international_cunnibal/models/score.dart';
import 'package:international_cunnibal/services/backend/leaderboard_backend.dart';

/// Placeholder Supabase backend adapter.
///
/// In production, replace the in-memory delegate with real Supabase queries.
class SupabaseLeaderboardBackend implements LeaderboardBackend {
  final LeaderboardBackend _delegate;

  SupabaseLeaderboardBackend({LeaderboardBackend? delegate})
      : _delegate = delegate ?? InMemoryLeaderboardBackend([]);

  @override
  Future<List<Score>> getTop({
    required LeaderboardFilter filter,
    int limit = 100,
  }) =>
      _delegate.getTop(filter: filter, limit: limit);

  @override
  Future<void> upsertScore(Score score) => _delegate.upsertScore(score);

  @override
  Future<void> upsertScores(List<Score> scores) =>
      _delegate.upsertScores(scores);

  @override
  Future<int> rankForUser(
    String userId, {
    required LeaderboardFilter filter,
    int limit = 1000,
  }) =>
      _delegate.rankForUser(userId, filter: filter, limit: limit);
}
