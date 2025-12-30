import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/score.dart';
import 'package:international_cunnibal/services/backend/leaderboard_backend.dart';
import 'package:international_cunnibal/services/leaderboard_service.dart';

void main() {
  group('LeaderboardService', () {
    test('rejects invalid endurance score', () async {
      final service = LeaderboardService(
        localUserId: 'test',
        backend: InMemoryLeaderboardBackend([]),
      );
      final invalidScore = Score(
        userId: 'test',
        enduranceScore: -50,
        streakDays: 0,
        totalSessions: 0,
        timestamp: DateTime.now(),
      );

      expect(
        () => service.submitScore(invalidScore),
        throwsA(isA<FormatException>()),
      );
    });

    test('enforces rate limiting', () async {
      var now = DateTime(2025, 1, 1, 12);
      DateTime clock() => now;

      final service = LeaderboardService(
        localUserId: 'test',
        clock: clock,
        backend: InMemoryLeaderboardBackend([]),
      );

      final score = Score(
        userId: 'test',
        enduranceScore: 80,
        streakDays: 1,
        totalSessions: 1,
        timestamp: now,
      );

      await service.submitScore(score);
      expect(
        () => service.submitScore(score),
        throwsA(isA<Exception>()),
      );

      now = now.add(const Duration(minutes: 6));
      await service.submitScore(score.copyWith(timestamp: now));
    });
  });
}
