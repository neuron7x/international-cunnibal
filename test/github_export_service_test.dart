import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/dictation_session.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:international_cunnibal/services/ui/github_export_service.dart';
import 'package:international_cunnibal/utils/constants.dart';
import 'package:international_cunnibal/utils/export_file_writer.dart';

class _FakeExportFileWriter extends ExportFileWriter {
  int writeCount = 0;
  String? lastPayload;
  String? lastFilename;

  @override
  Future<String> writeJson({
    required String filename,
    required String jsonPayload,
    String? directoryOverridePath,
  }) async {
    writeCount += 1;
    lastFilename = filename;
    lastPayload = jsonPayload;
    return directoryOverridePath == null
        ? 'memory://$filename'
        : '$directoryOverridePath/$filename';
  }

  @override
  Future<String> resolveDirectoryPath({String? directoryOverridePath}) async {
    return directoryOverridePath ?? 'memory://exports';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GitHubExportService', () {
    test('exports performance log to provided directory', () async {
      final service = GitHubExportService.testing(
        fileWriter: const ExportFileWriter(),
        now: () => DateTime(2025, 12, 26, 12, 30),
      );
      service.clearLogs();
      final tempDir = await Directory.systemTemp.createTemp(
        'github_export_service_test',
      );

      service.logMetrics(
        BiometricMetrics(
          consistencyScore: 80,
          frequency: 2.0,
          frequencyConfidence: 0.9,
          pcaVariance: const [50.0, 30.0, 20.0],
          movementDirection: MovementDirection.right,
          directionStability: 50,
          intensity: 60,
          patternScore: 75,
          endurance: EnduranceSnapshot.empty(),
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

      final exportPath = await service.exportPerformanceLog(
        directoryOverridePath: tempDir.path,
      );
      final file = File(exportPath);

      expect(file.existsSync(), isTrue);

      final content = jsonDecode(await file.readAsString()) as Map;
      expect(content['totalMetrics'], equals(1));
      expect(content['totalSessions'], equals(1));
      expect(content['summary']['avgSynchronization'], equals(90));

      service.clearLogs();
      await tempDir.delete(recursive: true);
    });

    test('auto-export triggers at threshold', () async {
      final writer = _FakeExportFileWriter();
      final service = GitHubExportService.testing(
        fileWriter: writer,
        now: () => DateTime(2025, 12, 26, 12, 45),
      );
      service.clearLogs();

      for (int i = 0; i < ExportConstants.autoExportThreshold; i++) {
        service.logMetrics(
          BiometricMetrics(
            consistencyScore: 80,
            frequency: 2.0,
            frequencyConfidence: 0.9,
            pcaVariance: const [50.0, 30.0, 20.0],
            movementDirection: MovementDirection.right,
            directionStability: 50,
            intensity: 60,
            patternScore: 75,
            endurance: EnduranceSnapshot.empty(),
            timestamp: DateTime(2025, 12, 26),
          ),
        );
      }

      expect(writer.writeCount, equals(1));
      expect(writer.lastFilename, contains('performance_log_'));
    });

    test('clearLogs clears both queues', () async {
      final writer = _FakeExportFileWriter();
      final service = GitHubExportService.testing(
        fileWriter: writer,
        now: () => DateTime(2025, 12, 26, 13, 0),
      );
      service.clearLogs();

      service.logMetrics(
        BiometricMetrics(
          consistencyScore: 80,
          frequency: 2.0,
          frequencyConfidence: 0.9,
          pcaVariance: const [50.0, 30.0, 20.0],
          movementDirection: MovementDirection.right,
          directionStability: 50,
          intensity: 60,
          patternScore: 75,
          endurance: EnduranceSnapshot.empty(),
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

      service.clearLogs();
      await service.exportPerformanceLog();

      final payload = jsonDecode(writer.lastPayload ?? '{}') as Map;
      expect(payload['totalMetrics'], equals(0));
      expect(payload['totalSessions'], equals(0));
    });
  });
}
