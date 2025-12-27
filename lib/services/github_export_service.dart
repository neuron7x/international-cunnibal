import 'package:international_cunnibal/core/metrics_exporter.dart';
import 'package:international_cunnibal/models/dictation_session.dart';
import 'package:international_cunnibal/models/metrics.dart';
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
  MetricsExportPayload? _lastExport;

  /// Log metrics data
  void logMetrics(BiometricMetrics metrics) {
    _metricsLog.add(metrics);

    // Auto-export if we have enough entries
    if (_metricsLog.length >= ExportConstants.autoExportThreshold) {
      _lastExport = exportPerformanceLog();
    }
  }

  /// Log dictation session
  void logSession(DictationSession session) {
    _sessionsLog.add(session);
  }

  MetricsExportPayload? get lastExport => _lastExport;

  /// Export performance log to JSON payload
  /// Produces a JSON string without performing any file I/O.
  MetricsExportPayload exportPerformanceLog({DateTime? timestamp}) {
    final payload = MetricsJsonExporter.buildPerformanceLog(
      metrics: _metricsLog,
      sessions: _sessionsLog,
      appVersion: ExportConstants.appVersion,
      timestamp: timestamp,
    );
    _lastExport = payload;
    return payload;
  }

  /// Clear logs after export
  void clearLogs() {
    _metricsLog.clear();
    _sessionsLog.clear();
    _lastExport = null;
  }
}
