import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/endurance_session_state.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/services/endurance_session_service.dart';
import 'package:international_cunnibal/utils/constants.dart';

void main() {
  group('EnduranceSessionService', () {
    EnduranceSnapshot goodSnapshot() {
      return EnduranceSnapshot(
        aperture: 0.2,
        apertureStability: EnduranceConstants.stabilityFloor + 10,
        fatigueIndicator: 0,
        enduranceTime: EnduranceConstants.targetHoldSeconds + 1,
        enduranceScore: 90,
        threshold: EnduranceConstants.defaultApertureThreshold,
      );
    }

    test('progresses from ready to hold to rest', () {
      final service = EnduranceSessionService();
      service.start(0.0);

      var state = service.ingest(
        snapshot: goodSnapshot(),
        tSeconds: EnduranceConstants.readySeconds + 0.1,
      );
      expect(state.phase, EnduranceSessionPhase.hold);

      state = service.ingest(
        snapshot: goodSnapshot(),
        tSeconds: EnduranceConstants.readySeconds +
            EnduranceConstants.targetHoldSeconds +
            0.2,
      );
      expect(state.phase, EnduranceSessionPhase.rest);
    });

    test('fatigue threshold forces summary', () {
      final service = EnduranceSessionService();
      service.start(0.0);

      final fatigueSnapshot = EnduranceSnapshot(
        aperture: 0.2,
        apertureStability: EnduranceConstants.stabilityFloor + 10,
        fatigueIndicator: EnduranceConstants.fatigueStopThreshold + 1,
        enduranceTime: EnduranceConstants.targetHoldSeconds + 1,
        enduranceScore: 90,
        threshold: EnduranceConstants.defaultApertureThreshold,
      );

      final state = service.ingest(
        snapshot: fatigueSnapshot,
        tSeconds: EnduranceConstants.readySeconds + 0.1,
      );

      expect(state.phase, EnduranceSessionPhase.summary);
    });

    test('cooldown prevents immediate restart', () {
      final service = EnduranceSessionService();
      service.start(0.0);
      service.stop(1.0);

      service.start(1.5);

      expect(service.state.canStart, isFalse);
      expect(service.state.prompt, contains('Cooldown'));
    });
  });
}
