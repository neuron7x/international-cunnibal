import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/services/endurance_game_logic_service.dart';
import 'package:international_cunnibal/utils/constants.dart';

void main() {
  group('EnduranceGameLogicService', () {
    test('levels up after consecutive hits', () {
      final service = EnduranceGameLogicService();
      service.reset();

      final snapshot = EnduranceSnapshot(
        aperture: 0.9,
        apertureStability: 100,
        fatigueIndicator: 0,
        enduranceTime: EnduranceConstants.targetHoldSeconds + 1,
        enduranceScore: 95,
        threshold: EnduranceConstants.defaultApertureThreshold,
      );

      service.ingest(snapshot);
      service.ingest(snapshot);

      expect(service.state.level, equals(2));
      expect(service.state.badges, equals(2));
      expect(service.state.streak, equals(0));
    });

    test('reset restores defaults', () {
      final service = EnduranceGameLogicService();
      service.reset();

      expect(service.state.level, equals(1));
      expect(service.state.badges, equals(0));
      expect(service.state.targetAperture,
          EnduranceConstants.defaultApertureThreshold);
    });
  });
}
