import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/dictation_session.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/services/github_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GitHubExportService', () {
    test('exports performance log to provided directory', () async {
      final service = GitHubExportService();
      service.clearLogs();
      final tempDir =
          await Directory.systemTemp.createTemp('github_export_service_test');

      service.logMetrics(
        BiometricMetrics(
          consistencyScore: 80,
          frequency: 2.0,
          pcaVariance: const [50.0, 30.0, 20.0],
          timestamp: DateTime(2025, 12, 26),
        ),
      );

      service.logSession(
        DictationSession(
          targetSymbol: 'A',
          startTime: DateTime(2025, 12, 26),
          rhythmTimestamps: const [0.0, 0.5, 1.0],
          synchronizationScore: 90,
        ),
      );

      final exportPath =
          await service.exportPerformanceLog(directoryOverride: tempDir);
      final file = File(exportPath);

      expect(file.existsSync(), isTrue);

      final content = jsonDecode(await file.readAsString()) as Map;
      expect(content['totalMetrics'], equals(1));
      expect(content['totalSessions'], equals(1));
      expect(content['summary']['avgSynchronization'], equals(90));

      service.clearLogs();
      await tempDir.delete(recursive: true);
    });
  });
}
