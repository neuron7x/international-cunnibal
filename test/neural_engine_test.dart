import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/services/neural_engine.dart';

void main() {
  group('NeuralEngine Tests', () {
    late NeuralEngine neuralEngine;

    setUp(() {
      neuralEngine = NeuralEngine();
    });

    tearDown(() {
      neuralEngine.dispose();
    });

    test('start/stop is idempotent', () {
      neuralEngine.start(enableTimer: false);
      neuralEngine.start(enableTimer: false);
      neuralEngine.stop();
      neuralEngine.stop();
    });

    test('NeuralEngine calculates metrics deterministically', () {
      neuralEngine.start(enableTimer: false);

      for (int i = 0; i < 10; i++) {
        final testData = TongueData(
          timestamp: DateTime.fromMillisecondsSinceEpoch(i * 20),
          position: Offset(0.5 + i * 0.01, 0.4 + i * 0.005),
          velocity: 1.0 + i * 0.1,
          acceleration: 0.0,
          landmarks: [Offset(0.5 + i * 0.01, 0.5)],
          isValidated: true,
        );
        neuralEngine.processTongueData(testData);
      }

      final first = neuralEngine.calculateMetricsNow();
      final second = neuralEngine.calculateMetricsNow();

      expect(first.consistencyScore, closeTo(second.consistencyScore, 1e-9));
      expect(first.frequency, closeTo(second.frequency, 1e-9));
      expect(first.pcaVariance, equals(second.pcaVariance));
      expect(first.pcaVariance.length, equals(3));
      expect(first.pcaVariance.last, equals(0.0));

      neuralEngine.stop();
    });

    test('PCA handles minimal inputs and constants', () {
      neuralEngine.start(enableTimer: false);
      neuralEngine.processTongueData(
        TongueData(
          timestamp: DateTime.fromMillisecondsSinceEpoch(0),
          position: const Offset(0.5, 0.5),
          velocity: 0,
          acceleration: 0,
          landmarks: const [Offset(0.5, 0.5)],
          isValidated: true,
        ),
      );
      final minimal = neuralEngine.calculateMetricsNow();
      expect(minimal.pcaVariance, equals(const [0.0, 0.0, 0.0]));

      for (int i = 1; i < 5; i++) {
        neuralEngine.processTongueData(
          TongueData(
            timestamp: DateTime.fromMillisecondsSinceEpoch(i * 10),
            position: const Offset(0.5, 0.5),
            velocity: 0,
            acceleration: 0,
            landmarks: const [Offset(0.5, 0.5)],
            isValidated: true,
          ),
        );
      }
      final constant = neuralEngine.calculateMetricsNow();
      expect(constant.pcaVariance, equals(const [0.0, 0.0, 0.0]));
    });

    test('PCA variance is scale invariant', () {
      neuralEngine.start(enableTimer: false);
      for (int i = 0; i < 10; i++) {
        final position = Offset(0.4 + i * 0.01, 0.6 + i * 0.02);
        neuralEngine.processTongueData(
          TongueData(
            timestamp: DateTime.fromMillisecondsSinceEpoch(i * 20),
            position: position,
            velocity: 1,
            acceleration: 0,
            landmarks: [position],
            isValidated: true,
          ),
        );
      }
      final base = neuralEngine.calculateMetricsNow();
      neuralEngine.stop();

      neuralEngine.start(enableTimer: false);
      for (int i = 0; i < 10; i++) {
        final position = Offset(0.4 + i * 0.02, 0.6 + i * 0.04);
        neuralEngine.processTongueData(
          TongueData(
            timestamp: DateTime.fromMillisecondsSinceEpoch(i * 20),
            position: position,
            velocity: 1,
            acceleration: 0,
            landmarks: [position],
            isValidated: true,
          ),
        );
      }
      final scaled = neuralEngine.calculateMetricsNow();

      expect(base.pcaVariance[0], closeTo(scaled.pcaVariance[0], 1e-6));
      expect(base.pcaVariance[1], closeTo(scaled.pcaVariance[1], 1e-6));
      expect(base.pcaVariance[2], equals(0.0));
      expect(scaled.pcaVariance[2], equals(0.0));
    });

    test('dispose closes resources', () {
      neuralEngine.start(enableTimer: false);
      neuralEngine.dispose();
      neuralEngine.dispose(); // idempotent
      // Should not throw when stopping after dispose
      neuralEngine.stop();
    });
  });
}
