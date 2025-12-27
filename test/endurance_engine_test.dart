import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/core/motion_metrics.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/services/endurance_engine.dart';
import 'package:international_cunnibal/utils/constants.dart';

void main() {
  group('EnduranceEngine', () {
    test('ingestSample returns empty snapshot with insufficient data', () {
      final engine = EnduranceEngine();
      final snapshot = engine.ingestSample(null);

      expect(snapshot, isA<EnduranceSnapshot>());
      expect(snapshot.enduranceScore, equals(0));
    });

    test('ingestLandmarks builds snapshot from full landmarks', () {
      final engine = EnduranceEngine(bufferSize: 4);
      final landmarks = List.generate(309, (_) => const Vector2(0.5, 0.5));
      landmarks[13] = const Vector2(0.5, 0.4);
      landmarks[14] = const Vector2(0.5, 0.6);
      landmarks[78] = const Vector2(0.4, 0.5);
      landmarks[308] = const Vector2(0.6, 0.5);

      engine.ingestLandmarks(tSeconds: 0.0, landmarks: landmarks);
      final snapshot =
          engine.ingestLandmarks(tSeconds: 0.5, landmarks: landmarks);

      expect(snapshot.aperture, closeTo(EnduranceConstants.apertureMax, 1e-6));
      expect(snapshot.threshold, EnduranceConstants.defaultApertureThreshold);
    });

    test('demoTick produces bounded snapshot', () {
      final engine = EnduranceEngine(bufferSize: 6);
      EnduranceSnapshot? snapshot;
      for (var i = 0; i < 6; i++) {
        snapshot = engine.demoTick(i.toDouble());
      }

      expect(snapshot, isNotNull);
      expect(snapshot!.aperture, inInclusiveRange(0.0, 1.0));
      expect(snapshot.enduranceScore, inInclusiveRange(0.0, 100.0));
    });
  });
}
