import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:international_cunnibal/models/achievement.dart';

class UserStats {
  final int enduranceScore;
  final int streakDays;
  final int totalSessions;
  final int? rank;

  const UserStats({
    required this.enduranceScore,
    required this.streakDays,
    required this.totalSessions,
    this.rank,
  });

  Map<String, dynamic> toJson() => {
        'enduranceScore': enduranceScore,
        'streakDays': streakDays,
        'totalSessions': totalSessions,
        'rank': rank,
      };
}

class ShareService {
  Future<File> generateShareCard({
    required UserStats stats,
    Achievement? achievement,
  }) async {
    final directory = await getTemporaryDirectory();
    final card = File('${directory.path}/share_card.txt');

    final buffer = StringBuffer()
      ..writeln('International Cunnibal')
      ..writeln('Endurance: ${stats.enduranceScore}')
      ..writeln('Streak: ${stats.streakDays} days')
      ..writeln('Sessions: ${stats.totalSessions}');

    if (stats.rank != null) {
      buffer.writeln('Leaderboard rank: #${stats.rank}');
    }
    if (achievement != null) {
      buffer.writeln('Achievement: ${achievement.name} (${achievement.tier.name})');
    }
    buffer.writeln('Challenge me at: https://bit.ly/international-cunnibal');

    await card.writeAsString(buffer.toString());
    return card;
  }

  Future<void> shareToSocial(File card) async {
    await Share.shareXFiles(
      [XFile(card.path)],
      subject: 'Can you beat my score?',
    );
  }
}
