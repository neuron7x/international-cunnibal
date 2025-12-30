import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/services/analytics/incremental_stats.dart';

class BatchProcessor {
  static Future<List<BiometricMetrics>> loadFromFile(String path) async {
    final file = File(path);
    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    final metricsList = (data['metrics'] as List?) ?? <dynamic>[];
    return metricsList
        .map(
          (m) => BiometricMetrics.fromJson(
            Map<String, dynamic>.from(m as Map),
          ),
        )
        .toList();
  }

  static Future<Map<String, dynamic>> processBatch({
    required List<BiometricMetrics> metrics,
    required int batchSize,
    required Future<void> Function(List<BiometricMetrics>) processor,
  }) async {
    final batches = <List<BiometricMetrics>>[];
    for (var i = 0; i < metrics.length; i += batchSize) {
      final end = math.min(i + batchSize, metrics.length);
      batches.add(metrics.sublist(i, end));
    }

    final stopwatch = Stopwatch()..start();
    for (final batch in batches) {
      await processor(batch);
    }
    stopwatch.stop();

    final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
    return {
      'totalMetrics': metrics.length,
      'batchCount': batches.length,
      'batchSize': batchSize,
      'processingTimeMs': stopwatch.elapsedMilliseconds,
      'throughput': elapsedSeconds == 0 ? metrics.length : metrics.length / elapsedSeconds,
    };
  }

  static Future<Map<String, dynamic>> aggregateParallel(
    List<BiometricMetrics> metrics,
    int workerCount,
  ) async {
    if (metrics.isEmpty) {
      return MetricsAggregator().summary();
    }

    final chunkSize = math.max(1, (metrics.length / workerCount).ceil());
    final chunks = <List<BiometricMetrics>>[];
    for (var i = 0; i < metrics.length; i += chunkSize) {
      final end = math.min(i + chunkSize, metrics.length);
      chunks.add(metrics.sublist(i, end));
    }

    final results = await Future.wait(
      chunks.map(
        (chunk) => compute(
          _aggregateChunk,
          chunk.map((m) => m.toJson()).toList(),
        ),
      ),
    );

    var combined = MetricsAggregator();
    for (final result in results) {
      combined = combined.combine(
        MetricsAggregator.fromMap(Map<String, dynamic>.from(result as Map)),
      );
    }

    return combined.summary();
  }
}

Map<String, dynamic> _aggregateChunk(List<dynamic> jsonMetrics) {
  final aggregator = MetricsAggregator();
  for (final m in jsonMetrics) {
    aggregator.ingest(
      BiometricMetrics.fromJson(Map<String, dynamic>.from(m as Map)),
    );
  }
  return aggregator.toMap();
}
