import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/core/endurance_metrics.dart';
import 'package:international_cunnibal/core/motion_metrics.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/services/endurance_engine.dart';
import 'package:international_cunnibal/services/endurance_game_logic_service.dart';
import 'package:international_cunnibal/services/endurance_session_service.dart';
import 'package:international_cunnibal/utils/constants.dart';

ApertureSample _sample(double t, double apertureValue) {
  const width = 0.5;
  final vertical = (apertureValue * width).clamp(0.0, width);
  final half = vertical / 2;
  return ApertureSample(
    t: t,
    upperLip: Vector2(0.5, 0.5 - half),
    lowerLip: Vector2(0.5, 0.5 + half),
    leftCorner: const Vector2(0.25, 0.5),
    rightCorner: const Vector2(0.75, 0.5),
  );
}

EnduranceSnapshot _snapshot({
  double aperture = 0.22,
  double stability = 70,
  double fatigue = 0,
  double enduranceTime = 2.0,
}) {
  return EnduranceSnapshot(
    aperture: aperture,
    apertureStability: stability,
    fatigueIndicator: fatigue,
    enduranceTime: enduranceTime,
    enduranceScore: 80,
    threshold: EnduranceConstants.defaultApertureThreshold,
  );
}

void main() {
  group('EnduranceEngine', () {
    test('returns empty snapshot until buffer has enough samples', () {
      final engine = EnduranceEngine(bufferSize: 3, apertureThreshold: 0.2);
      final result = engine.ingestSample(_sample(0.0, 0.25));
      expect(result.enduranceScore, equals(0));
      expect(result.threshold, equals(0.2));
    });

    test('snapshot is deterministic for identical buffer', () {
      final engine = EnduranceEngine(bufferSize: 3, apertureThreshold: 0.2);
      engine.ingestSample(_sample(0.0, 0.25));
      final first = engine.ingestSample(_sample(0.5, 0.25));
      final second = engine.snapshot();
      expect(first.aperture, closeTo(second.aperture, 1e-6));
      expect(first.enduranceScore, closeTo(second.enduranceScore, 1e-6));
    });
  });

  group('EnduranceSessionService', () {
    test('transitions into hold after ready phase', () {
      final service = EnduranceSessionService();
      service.start(0);
      final state = service.ingest(
        snapshot: _snapshot(),
        tSeconds: EnduranceConstants.readySeconds + 0.1,
      );
      expect(state.phase, equals(EnduranceSessionPhase.hold));
    });

    test('auto-pauses when stability drops', () {
      final service = EnduranceSessionService();
      service.start(0);
      service.ingest(
        snapshot: _snapshot(),
        tSeconds: EnduranceConstants.readySeconds + 0.1,
      );
      final state = service.ingest(
        snapshot: _snapshot(stability: 20),
        tSeconds: EnduranceConstants.readySeconds + 0.2,
      );
      expect(state.phase, equals(EnduranceSessionPhase.rest));
      expect(state.autoPaused, isTrue);
    });
  });

  group('EnduranceGameLogicService', () {
    test('levels up after streak threshold', () {
      final service = EnduranceGameLogicService();
      service.reset();
      final snapshot = _snapshot(
        aperture: 0.3,
        stability: EnduranceConstants.stabilityFloor + 10,
        enduranceTime: EnduranceConstants.targetHoldSeconds + 0.5,
      );

      service.ingest(snapshot);
      service.ingest(snapshot);

      expect(service.state.level, equals(2));
      expect(service.state.streak, equals(0));
      expect(service.state.targetAperture,
          greaterThanOrEqualTo(EnduranceConstants.defaultApertureThreshold));
    });
  });
}
