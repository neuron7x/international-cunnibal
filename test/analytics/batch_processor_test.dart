import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:international_cunnibal/services/analytics/batch_processor.dart';

void main() {
  group('BatchProcessor', () {
    test('loads metrics from file', () async {
      final metrics = [
        BiometricMetrics(
          consistencyScore: 50,
          frequency: 2.0,
          frequencyConfidence: 0.8,
          pcaVariance: const [0.4, 0.3, 0.3],
          movementDirection: MovementDirection.up,
          directionStability: 50,
          intensity: 50,
          patternScore: 50,
          endurance: EnduranceSnapshot.empty(),
          timestamp: DateTime(2025, 12, 26),
        ),
      ];

      final tempFile = await File(
        '${(await Directory.systemTemp.createTemp()).path}/metrics.json',
      ).create(recursive: true);

      await tempFile.writeAsString(jsonEncode({
        'metrics': metrics.map((m) => m.toJson()).toList(),
      }));

      final loaded = await BatchProcessor.loadFromFile(tempFile.path);

      expect(loaded.length, equals(1));
      expect(loaded.first.consistencyScore, equals(50));
    });

    test('processes batches sequentially', () async {
      final metrics = List.generate(
        5,
        (i) => BiometricMetrics(
          consistencyScore: 50 + i,
          frequency: 2.0,
          frequencyConfidence: 0.8,
          pcaVariance: const [0.4, 0.3, 0.3],
          movementDirection: MovementDirection.up,
          directionStability: 50,
          intensity: 50,
          patternScore: 50,
          endurance: EnduranceSnapshot.empty(),
          timestamp: DateTime(2025, 12, 26),
        ),
      );

      var processed = 0;
      final result = await BatchProcessor.processBatch(
        metrics: metrics,
        batchSize: 2,
        processor: (batch) async {
          processed += batch.length;
        },
      );

      expect(processed, equals(metrics.length));
      expect(result['batchCount'], equals(3));
    });
  });
}
