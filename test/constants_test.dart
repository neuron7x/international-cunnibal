import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/utils/constants.dart';

void main() {
  group('BioTrackingConstants', () {
    test('defines expected simulation and frame constants', () {
      expect(BioTrackingConstants.simulationAmplitudeX, 0.3);
      expect(BioTrackingConstants.simulationAmplitudeY, 0.2);
      expect(BioTrackingConstants.simulationFrequencyMultiplier, 1.5);
      expect(BioTrackingConstants.simulationPeriod, 2.0);
      expect(BioTrackingConstants.framesPerSecond, 30);
      expect(BioTrackingConstants.frameProcessingIntervalMs, 33);
    });
  });

  group('RhythmPatterns', () {
    test('returns configured patterns for known symbols', () {
      expect(
        RhythmPatterns.getPattern('A'),
        [RhythmPatterns.shortMovement, RhythmPatterns.longMovement],
      );
      expect(
        RhythmPatterns.getPattern('Z'),
        [
          RhythmPatterns.longMovement,
          RhythmPatterns.longMovement,
          RhythmPatterns.shortMovement,
          RhythmPatterns.shortMovement,
        ],
      );
    });

    test('falls back to default short pattern for unknown symbols', () {
      expect(
        RhythmPatterns.getPattern('?'),
        [RhythmPatterns.shortMovement, RhythmPatterns.shortMovement],
      );
    });
  });

  group('NeuralEngineConstants', () {
    test('defines expected buffer and metric constants', () {
      expect(NeuralEngineConstants.bufferSize, 100);
      expect(NeuralEngineConstants.metricsUpdateIntervalSeconds, 1);
      expect(NeuralEngineConstants.expectedAmplitude, 0.4);
      expect(NeuralEngineConstants.stdDevScalingFactor, 50.0);
      expect(NeuralEngineConstants.velocityChangeThreshold, 0.5);
    });
  });

  group('EnduranceConstants', () {
    test('defines expected endurance thresholds', () {
      expect(EnduranceConstants.defaultApertureThreshold, 0.18);
      expect(EnduranceConstants.apertureMin, 0.0);
      expect(EnduranceConstants.apertureMax, 0.6);
      expect(EnduranceConstants.apertureSafetyMin, 0.08);
      expect(EnduranceConstants.apertureSafetyMax, 0.55);
      expect(EnduranceConstants.stabilityFloor, 55);
      expect(EnduranceConstants.targetHoldSeconds, 1.5);
      expect(EnduranceConstants.apertureStep, 0.02);
      expect(EnduranceConstants.stabilityStep, 5);
      expect(EnduranceConstants.timeStep, 0.5);
      expect(EnduranceConstants.readySeconds, 2.0);
      expect(EnduranceConstants.restSeconds, 4.0);
      expect(EnduranceConstants.maxSessionSeconds, 45.0);
      expect(EnduranceConstants.cooldownSeconds, 20.0);
      expect(EnduranceConstants.fatigueStopThreshold, 65.0);
      expect(EnduranceConstants.stabilityDropThreshold, 15.0);
    });
  });

  group('ExportConstants', () {
    test('defines expected export configuration', () {
      expect(ExportConstants.autoExportThreshold, 100);
      expect(ExportConstants.appVersion, '1.0.0');
    });
  });
}
