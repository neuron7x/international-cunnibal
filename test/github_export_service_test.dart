import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/dictation_session.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:international_cunnibal/services/ui/github_export_service.dart';
import 'package:international_cunnibal/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GitHubExportService', () {
    test('auto-export triggers at threshold', () async {
      Map<String, dynamic>? lastPayload;
      final service = GitHubExportService.testing(
        onAutoExport: (payload) => lastPayload = payload,
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

      expect(lastPayload, isNotNull);
      final counts = lastPayload!['counts'] as Map<String, dynamic>;
      expect(counts['metricsCount'], equals(ExportConstants.autoExportThreshold));
    });

    test('clearLogs clears both queues', () {
      final service = GitHubExportService.testing(
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
      final payload = service.buildExportPayload();
      final counts = payload['counts'] as Map<String, dynamic>;
      expect(counts['metricsCount'], equals(0));
      expect(counts['sessionsCount'], equals(0));
    });

    test('payload contains required keys and avoids raw fields', () {
      final service = GitHubExportService.testing(
        now: () => DateTime.utc(2025, 12, 26, 13, 30),
      );
      service.clearLogs();

      service.logMetrics(
        BiometricMetrics(
          consistencyScore: 82,
          frequency: 1.8,
          frequencyConfidence: 0.88,
          pcaVariance: const [50.0, 30.0, 20.0],
          movementDirection: MovementDirection.right,
          directionStability: 55,
          intensity: 65,
          patternScore: 74,
          endurance: EnduranceSnapshot.empty(),
          timestamp: DateTime(2025, 12, 26),
        ),
      );
      service.logSession(
        DictationSession(
          targetSymbol: 'B',
          startTime: DateTime.utc(2025, 12, 26, 13, 0),
          rhythmTimestamps: const [0.0, 0.4, 0.9],
          synchronizationScore: 92,
        ),
      );

      final payload = service.buildExportPayload();

      expect(payload['schemaVersion'], equals(1));
      expect(DateTime.parse(payload['exportedAtUtc'] as String).isUtc, isTrue);
      expect(payload['appVersion'], equals(ExportConstants.appVersion));
      expect(payload['counts'], isA<Map<String, dynamic>>());
      expect(payload['summary'], isA<Map<String, dynamic>>());
      expect(payload['sessions'], isA<List<dynamic>>());

      final payloadString = payload.toString();
      expect(payloadString.contains('rhythmTimestamps'), isFalse);
      expect(payloadString.contains('pcaVariance'), isFalse);
    });
  });
}
