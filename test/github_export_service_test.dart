import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/dictation_session.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:international_cunnibal/services/github_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GitHubExportService', () {
    test('exports performance log payload', () async {
      final service = GitHubExportService();
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

      final payload = service.exportPerformanceLog(
        timestamp: DateTime(2025, 12, 26, 12, 0, 0),
      );
      final content = payload.data;
      expect(content['totalMetrics'], equals(1));
      expect(content['totalSessions'], equals(1));
      expect(content['summary']['avgSynchronization'], equals(90));

      service.clearLogs();
    });
  });
}
