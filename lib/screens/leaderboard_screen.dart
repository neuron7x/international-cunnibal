import 'package:flutter/material.dart';
import 'package:international_cunnibal/models/achievement.dart';
import 'package:international_cunnibal/models/score.dart';
import 'package:international_cunnibal/services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late LeaderboardFilter _filter;
  late Future<List<Score>> _scoresFuture;
  final LeaderboardService _service =
      LeaderboardService(localUserId: 'local-user');

  @override
  void initState() {
    super.initState();
    _filter = LeaderboardFilter.allTime;
    _scoresFuture = _service.getTop100(filter: _filter);
  }

  void _setFilter(LeaderboardFilter filter) {
    setState(() {
      _filter = filter;
      _scoresFuture = _service.getTop100(filter: filter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Leaderboard'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Daily'),
                selected: _filter == LeaderboardFilter.daily,
                onSelected: (_) => _setFilter(LeaderboardFilter.daily),
              ),
              ChoiceChip(
                label: const Text('Weekly'),
                selected: _filter == LeaderboardFilter.weekly,
                onSelected: (_) => _setFilter(LeaderboardFilter.weekly),
              ),
              ChoiceChip(
                label: const Text('All-Time'),
                selected: _filter == LeaderboardFilter.allTime,
                onSelected: (_) => _setFilter(LeaderboardFilter.allTime),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Score>>(
              future: _scoresFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final scores = snapshot.data!;
                if (scores.isEmpty) {
                  return const Center(
                    child: Text('No scores yet. Complete a session to join!'),
                  );
                }
                return ListView.builder(
                  itemCount: scores.length,
                  itemBuilder: (context, index) {
                    final score = scores[index];
                    final isYou = score.userId == _service.localUserId;
                    return Card(
                      color: isYou
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(score.displayName ?? 'Anonymous'),
                        subtitle: Text(
                          'Endurance ${score.enduranceScore} • Streak ${score.streakDays}d • Sessions ${score.totalSessions}',
                        ),
                        trailing: _badgeIcon(score.badge),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeIcon(AchievementTier tier) {
    IconData icon;
    Color? color;
    switch (tier) {
      case AchievementTier.bronze:
        icon = Icons.emoji_events;
        color = Colors.brown[400];
        break;
      case AchievementTier.silver:
        icon = Icons.emoji_events;
        color = Colors.grey[400];
        break;
      case AchievementTier.gold:
        icon = Icons.emoji_events;
        color = Colors.amber[400];
        break;
      case AchievementTier.diamond:
        icon = Icons.diamond;
        color = Colors.blue[300];
        break;
    }
    return Icon(icon, color: color);
  }
}
