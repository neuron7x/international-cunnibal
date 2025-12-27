import 'dart:convert';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/dictation_session.dart';
import 'package:international_cunnibal/utils/constants.dart';

/// GitHub Performance Log Export Service
/// Automated export of performance logs for GitHub integration
/// Reference: Automated GitHub performance log exports (2025-11-30)
class GitHubExportService {
  static final GitHubExportService _instance = GitHubExportService._internal();
  factory GitHubExportService() => _instance;
  GitHubExportService._internal({
    void Function(Map<String, dynamic> payload)? onAutoExport,
    DateTime Function()? now,
  })  : _onAutoExport = onAutoExport,
        _now = now ?? DateTime.now;

  GitHubExportService.testing({
    void Function(Map<String, dynamic> payload)? onAutoExport,
    DateTime Function()? now,
  })  : _onAutoExport = onAutoExport,
        _now = now ?? DateTime.now;

  static const int _schemaVersion = 1;

  final void Function(Map<String, dynamic> payload)? _onAutoExport;
  final DateTime Function() _now;

  final List<BiometricMetrics> _metricsLog = [];
  final List<DictationSession> _sessionsLog = [];

  /// Log metrics data
  void logMetrics(BiometricMetrics metrics) {
    _metricsLog.add(metrics);
    
    // Auto-export if we have enough entries
    if (_metricsLog.length >= ExportConstants.autoExportThreshold) {
      _onAutoExport?.call(buildExportPayload());
    }
  }

  /// Log dictation session
  void logSession(DictationSession session) {
    _sessionsLog.add(session);
  }

  /// Export performance log to file
  /// Creates a JSON file with all metrics and sessions
  Map<String, dynamic> buildExportPayload() {
    final exportedAt = _now().toUtc();
    final metricsCount = _metricsLog.length;
    final sessionsCount = _sessionsLog.length;

    return {
      'schemaVersion': _schemaVersion,
      'exportedAtUtc': exportedAt.toIso8601String(),
      'appVersion': ExportConstants.appVersion,
      'counts': {
        'metricsCount': metricsCount,
        'sessionsCount': sessionsCount,
      },
      'summary': _generateSummary(),
      'sessions': _buildSessionSummaries(),
    };
  }

  String buildExportPayloadJson({bool pretty = true}) {
    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(buildExportPayload());
  }

  /// Generate summary statistics
  Map<String, dynamic> _generateSummary() {
    final metricsSummary = _aggregateMetrics();
    final sessionSummary = _aggregateSessions();
    return {
      'metrics': metricsSummary,
      'sessions': sessionSummary,
    };
  }

  /// Clear logs after export
  void clearLogs() {
    _metricsLog.clear();
    _sessionsLog.clear();
  }

  Map<String, dynamic> _aggregateMetrics() {
    if (_metricsLog.isEmpty) {
      return _emptyMetricAggregates();
    }

    return {
      'consistencyScore': _statsFor(_metricsLog.map((m) => m.consistencyScore)),
      'frequency': _statsFor(_metricsLog.map((m) => m.frequency)),
      'frequencyConfidence':
          _statsFor(_metricsLog.map((m) => m.frequencyConfidence)),
      'directionStability':
          _statsFor(_metricsLog.map((m) => m.directionStability)),
      'intensity': _statsFor(_metricsLog.map((m) => m.intensity)),
      'patternScore': _statsFor(_metricsLog.map((m) => m.patternScore)),
      'enduranceScore':
          _statsFor(_metricsLog.map((m) => m.endurance.enduranceScore)),
    };
  }

  Map<String, dynamic> _aggregateSessions() {
    if (_sessionsLog.isEmpty) {
      return {
        'meanSynchronization': 0.0,
        'minSynchronization': 0.0,
        'maxSynchronization': 0.0,
        'meanRhythmConsistency': 0.0,
      };
    }

    final syncScores = _sessionsLog.map((s) => s.synchronizationScore);
    final rhythmScores = _sessionsLog.map((s) => s.rhythmConsistency);

    return {
      'meanSynchronization': _mean(syncScores),
      'minSynchronization': syncScores.reduce(_min),
      'maxSynchronization': syncScores.reduce(_max),
      'meanRhythmConsistency': _mean(rhythmScores),
    };
  }

  List<Map<String, dynamic>> _buildSessionSummaries() {
    return _sessionsLog.map((session) {
      final durationSeconds = session.rhythmTimestamps.isEmpty
          ? 0.0
          : (session.rhythmTimestamps.last - session.rhythmTimestamps.first)
              .clamp(0.0, double.infinity);
      return {
        'targetSymbol': session.targetSymbol,
        'startTimeUtc': session.startTime.toUtc().toIso8601String(),
        'durationSeconds': durationSeconds,
        'synchronizationScore': session.synchronizationScore,
        'rhythmConsistency': session.rhythmConsistency,
      };
    }).toList();
  }

  Map<String, dynamic> _statsFor(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) {
      return {'mean': 0.0, 'min': 0.0, 'max': 0.0};
    }
    final minValue = list.reduce(_min);
    final maxValue = list.reduce(_max);
    return {
      'mean': _mean(list),
      'min': minValue,
      'max': maxValue,
    };
  }

  double _mean(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0.0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  double _min(double a, double b) => a < b ? a : b;
  double _max(double a, double b) => a > b ? a : b;

  Map<String, dynamic> _emptyMetricAggregates() {
    return {
      'consistencyScore': {'mean': 0.0, 'min': 0.0, 'max': 0.0},
      'frequency': {'mean': 0.0, 'min': 0.0, 'max': 0.0},
      'frequencyConfidence': {'mean': 0.0, 'min': 0.0, 'max': 0.0},
      'directionStability': {'mean': 0.0, 'min': 0.0, 'max': 0.0},
      'intensity': {'mean': 0.0, 'min': 0.0, 'max': 0.0},
      'patternScore': {'mean': 0.0, 'min': 0.0, 'max': 0.0},
      'enduranceScore': {'mean': 0.0, 'min': 0.0, 'max': 0.0},
    };
  }
}
