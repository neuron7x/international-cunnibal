import 'dart:convert';

import 'package:international_cunnibal/models/dictation_session.dart';
import 'package:international_cunnibal/models/metrics.dart';

class MetricsExportPayload {
  final Map<String, dynamic> data;
  final String json;

  MetricsExportPayload({
    required this.data,
    required this.json,
  });
}

/// Platform-agnostic metrics exporter.
///
/// Produces JSON payloads without performing any file I/O.
class MetricsJsonExporter {
  static MetricsExportPayload buildPerformanceLog({
    required List<BiometricMetrics> metrics,
    required List<DictationSession> sessions,
    required String appVersion,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final data = {
      'exportTimestamp': now.toIso8601String(),
      'appVersion': appVersion,
      'totalMetrics': metrics.length,
      'totalSessions': sessions.length,
      'metrics': metrics.map((m) => m.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'summary': _generateSummary(metrics, sessions),
    };

    return MetricsExportPayload(
      data: data,
      json: const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  static Map<String, dynamic> _generateSummary(
    List<BiometricMetrics> metrics,
    List<DictationSession> sessions,
  ) {
    if (metrics.isEmpty) {
      return {
        'avgConsistency': 0.0,
        'avgFrequency': 0.0,
        'avgEnduranceScore': 0.0,
        'avgSynchronization': 0.0,
        'totalSessions': sessions.length,
      };
    }

    final avgConsistency = metrics
            .map((m) => m.consistencyScore)
            .reduce((a, b) => a + b) /
        metrics.length;

    final avgFrequency =
        metrics.map((m) => m.frequency).reduce((a, b) => a + b) /
            metrics.length;
    final avgEndurance = metrics
            .map((m) => m.endurance.enduranceScore)
            .reduce((a, b) => a + b) /
        metrics.length;

    final avgSyncScore = sessions.isEmpty
        ? 0.0
        : sessions
                .map((s) => s.synchronizationScore)
                .reduce((a, b) => a + b) /
            sessions.length;

    return {
      'avgConsistency': avgConsistency,
      'avgFrequency': avgFrequency,
      'avgEnduranceScore': avgEndurance,
      'avgSynchronization': avgSyncScore,
      'totalSessions': sessions.length,
    };
  }
}
