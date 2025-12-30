import 'package:flutter/material.dart';
import 'package:international_cunnibal/models/achievement.dart';
import 'package:international_cunnibal/models/score.dart';
import 'package:international_cunnibal/services/leaderboard_service.dart';
import 'package:international_cunnibal/services/user_id_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late LeaderboardFilter _filter;
  Future<List<Score>>? _scoresFuture;
  LeaderboardService? _service;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _filter = LeaderboardFilter.allTime;
    _initializeService();
  }

  Future<void> _initializeService() async {
    final userId = await UserIdProvider.getUserId();
    if (!mounted) return;
    setState(() {
      _service = LeaderboardService(localUserId: userId);
      _scoresFuture = _service!.getTop100(filter: _filter);
      _isInitialized = true;
    });
  }

  void _setFilter(LeaderboardFilter filter) {
    if (_service == null) return;
    setState(() {
      _filter = filter;
      _scoresFuture = _service!.getTop100(filter: filter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Global Leaderboard')),
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
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 72, color: Colors.red.shade400),
                          const SizedBox(height: 24),
                          Text('Failed to load', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          Text(
                            snapshot.error.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_service != null) {
                                setState(() => _scoresFuture = _service!.getTop100(filter: _filter));
                              }
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || !_isInitialized) {
                  return const Center(child: CircularProgressIndicator());
                }
                final scores = snapshot.data!;
                if (scores.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 72, color: Colors.grey.shade400),
                        const SizedBox(height: 24),
                        const Text('No scores yet'),
                        const SizedBox(height: 12),
                        const Text('Complete a session to join!'),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: scores.length,
                  itemBuilder: (context, index) {
                    final score = scores[index];
                    final isYou = _service != null && score.userId == _service!.localUserId;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: isYou ? Theme.of(context).colorScheme.secondaryContainer : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: index < 3 ? Colors.amber.shade400 : Colors.grey.shade300,
                          child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(score.displayName ?? 'Anonymous'),
                        subtitle: Text('Endurance ${score.enduranceScore} • ${score.streakDays}d • ${score.totalSessions} sessions'),
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
      case AchievementTier.bronze: icon = Icons.emoji_events; color = Colors.brown[400]; break;
      case AchievementTier.silver: icon = Icons.emoji_events; color = Colors.grey[400]; break;
      case AchievementTier.gold: icon = Icons.emoji_events; color = Colors.amber[400]; break;
      case AchievementTier.diamond: icon = Icons.diamond; color = Colors.blue[300]; break;
    }
    return Icon(icon, color: color);
  }
}
