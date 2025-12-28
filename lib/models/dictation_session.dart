/// Symbol Dictation session data
/// Reference: Partner-led Symbol Dictation feature (2025-11-30)
class DictationSession {
  final String targetSymbol; // A-Z
  final DateTime startTime;
  final List<double> rhythmTimestamps; // Timestamps of movements
  final double synchronizationScore; // 0-100

  const DictationSession({
    required this.targetSymbol,
    required this.startTime,
    required this.rhythmTimestamps,
    required this.synchronizationScore,
  });

  /// Calculate rhythm consistency
  double get rhythmConsistency {
    if (rhythmTimestamps.length < 2) return 0.0;

    // Calculate intervals between movements
    final intervals = <double>[];
    for (int i = 1; i < rhythmTimestamps.length; i++) {
      intervals.add(rhythmTimestamps[i] - rhythmTimestamps[i - 1]);
    }

    // Calculate standard deviation of intervals
    if (intervals.isEmpty) return 0.0;

    final mean = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance =
        intervals
            .map((interval) => (interval - mean) * (interval - mean))
            .reduce((a, b) => a + b) /
        intervals.length;

    // Convert to consistency score (lower std dev = higher consistency)
    return 100.0 / (1.0 + variance);
  }

  Map<String, dynamic> toJson() {
    return {
      'targetSymbol': targetSymbol,
      'startTime': startTime.toIso8601String(),
      'rhythmTimestamps': rhythmTimestamps,
      'synchronizationScore': synchronizationScore,
      'rhythmConsistency': rhythmConsistency,
    };
  }
}
