import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:international_cunnibal/models/dictation_session.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/schema_version.dart';
import 'package:international_cunnibal/services/analytics/incremental_stats.dart';
import 'package:international_cunnibal/utils/constants.dart';
import 'package:international_cunnibal/utils/export_file_writer.dart';
import 'package:international_cunnibal/validators/metrics_validator.dart';

/// GitHub Performance Log Export Service
/// Automated export of performance logs for GitHub integration
/// Reference: Automated GitHub performance log exports (2025-11-30)
class GitHubExportService {
  static final GitHubExportService _instance = GitHubExportService._internal();
  factory GitHubExportService() => _instance;
  GitHubExportService._internal({
    ExportFileWriter? fileWriter,
    DateTime Function()? now,
  }) : _fileWriter = fileWriter ?? const ExportFileWriter(),
       _now = now ?? DateTime.now;

  GitHubExportService.testing({
    required ExportFileWriter fileWriter,
    DateTime Function()? now,
  }) : _fileWriter = fileWriter,
       _now = now ?? DateTime.now;

  final ExportFileWriter _fileWriter;
  final DateTime Function() _now;

  final List<BiometricMetrics> _metricsLog = [];
  final List<DictationSession> _sessionsLog = [];
  final MetricsAggregator _aggregator = MetricsAggregator();

  /// Log metrics data
  void logMetrics(BiometricMetrics metrics) {
    final errors = MetricsValidator.validate(metrics);
    if (errors.isNotEmpty) {
      throw ArgumentError('Invalid metrics: $errors');
    }

    _metricsLog.add(metrics);
    _aggregator.ingest(metrics);

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
  Future<String> exportPerformanceLog({String? directoryOverridePath}) async {
    final now = _now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final filename = 'performance_log_$timestamp.json';

    final data = {
      'schemaVersion': SchemaVersion.current,
      'exportTimestamp': now.toIso8601String(),
      'appVersion': ExportConstants.appVersion,
      'totalMetrics': _metricsLog.length,
      'totalSessions': _sessionsLog.length,
      'metrics': _metricsLog.map((m) => m.toJson()).toList(),
      'sessions': _sessionsLog.map((s) => s.toJson()).toList(),
      'summary': _generateSummary(),
    };

    return _fileWriter.writeJson(
      filename: filename,
      jsonPayload: const JsonEncoder.withIndent('  ').convert(data),
      directoryOverridePath: directoryOverridePath,
    );
  }

  /// Generate summary statistics
  Map<String, dynamic> _generateSummary() {
    final summary = _aggregator.summary();
    final avgSyncScore = _sessionsLog.isEmpty
        ? 0.0
        : _sessionsLog
                  .map((s) => s.synchronizationScore)
                  .reduce((a, b) => a + b) /
              _sessionsLog.length;

    return {
      ...summary,
      'avgSynchronization': avgSyncScore,
      'totalSessions': _sessionsLog.length,
    };
  }

  /// Clear logs after export
  void clearLogs() {
    _metricsLog.clear();
    _sessionsLog.clear();
    _aggregator.reset();
  }

  /// Get export directory path
  Future<String> getExportDirectory({String? directoryOverridePath}) async {
    return _fileWriter.resolveDirectoryPath(
      directoryOverridePath: directoryOverridePath,
    );
  }
}
