import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/dictation_session.dart';
import 'package:international_cunnibal/utils/constants.dart';

/// GitHub Performance Log Export Service
/// Automated export of performance logs for GitHub integration
/// Reference: Automated GitHub performance log exports (2025-11-30)
class GitHubExportService {
  static final GitHubExportService _instance = GitHubExportService._internal();
  factory GitHubExportService() => _instance;
  GitHubExportService._internal();

  final List<BiometricMetrics> _metricsLog = [];
  final List<DictationSession> _sessionsLog = [];

  /// Log metrics data
  void logMetrics(BiometricMetrics metrics) {
    _metricsLog.add(metrics);
    
    // Auto-export if we have enough entries
    if (_metricsLog.length >= ExportConstants.autoExportThreshold) {
      exportPerformanceLog();
    }
  }

  /// Log dictation session
  void logSession(DictationSession session) {
    _sessionsLog.add(session);
  }

  /// Export performance log to file
  /// Creates a JSON file with all metrics and sessions
  Future<String> exportPerformanceLog() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'performance_log_$timestamp.json';
    final file = File('${directory.path}/$filename');

    final data = {
      'exportTimestamp': DateTime.now().toIso8601String(),
      'appVersion': ExportConstants.appVersion,
      'totalMetrics': _metricsLog.length,
      'totalSessions': _sessionsLog.length,
      'metrics': _metricsLog.map((m) => m.toJson()).toList(),
      'sessions': _sessionsLog.map((s) => s.toJson()).toList(),
      'summary': _generateSummary(),
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );

    return file.path;
  }

  /// Generate summary statistics
  Map<String, dynamic> _generateSummary() {
    if (_metricsLog.isEmpty) {
      return {
        'avgConsistency': 0.0,
        'avgFrequency': 0.0,
        'totalSessions': 0,
      };
    }

    final avgConsistency = _metricsLog
        .map((m) => m.consistencyScore)
        .reduce((a, b) => a + b) / _metricsLog.length;

    final avgFrequency = _metricsLog
        .map((m) => m.frequency)
        .reduce((a, b) => a + b) / _metricsLog.length;

    final avgSyncScore = _sessionsLog.isEmpty
        ? 0.0
        : _sessionsLog
            .map((s) => s.synchronizationScore)
            .reduce((a, b) => a + b) / _sessionsLog.length;

    return {
      'avgConsistency': avgConsistency,
      'avgFrequency': avgFrequency,
      'avgSynchronization': avgSyncScore,
      'totalSessions': _sessionsLog.length,
    };
  }

  /// Clear logs after export
  void clearLogs() {
    _metricsLog.clear();
    _sessionsLog.clear();
  }

  /// Get export directory path
  Future<String> getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
