import 'package:international_cunnibal/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionTracker {
  final SharedPreferences _prefs;

  static const String _keyPrefix = 'session_';

  SessionTracker(this._prefs);

  /// Check if user can start new session
  Future<SessionEligibility> checkEligibility() async {
    final lastSession = await _getLastSession();

    // Rule 1: 24h minimum between sessions
    if (lastSession != null) {
      final elapsed = DateTime.now().difference(lastSession);
      if (elapsed < const Duration(hours: 24)) {
        final remaining = const Duration(hours: 24) - elapsed;
        return SessionEligibility(
          canStart: false,
          reason:
              'Need ${remaining.inHours}h more rest before starting another session.',
        );
      }
    }

    // Rule 2: Max sessions per week
    final weekCount = await _getThisWeekSessionCount();
    if (weekCount >= SafeEnduranceLimits.maxWeeklySessions) {
      return SessionEligibility(
        canStart: false,
        reason: 'Weekly limit reached (${SafeEnduranceLimits.maxWeeklySessions} max). Next: Monday.',
      );
    }

    return SessionEligibility(canStart: true);
  }

  Future<void> recordSession() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final key = '$_keyPrefix$timestamp';
    await _prefs.setInt(key, timestamp);
  }

  Future<int> _getThisWeekSessionCount() async {
    final now = DateTime.now();
    final weekStartDate = now.subtract(Duration(days: now.weekday - 1));
    final weekStart =
        DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day);

    final allKeys = _prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    int count = 0;

    for (final key in allKeys) {
      final timestamp = _prefs.getInt(key);
      if (timestamp != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (!date.isBefore(weekStart)) count++;
      }
    }

    return count;
  }

  Future<DateTime?> _getLastSession() async {
    final allKeys = _prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    if (allKeys.isEmpty) return null;

    final timestamps = allKeys
        .map((k) => _prefs.getInt(k))
        .whereType<int>()
        .toList()
      ..sort();

    return DateTime.fromMillisecondsSinceEpoch(timestamps.last);
  }
}

class SessionEligibility {
  final bool canStart;
  final String? reason;

  SessionEligibility({required this.canStart, this.reason});
}
