import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/services/neural_engine.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:flutter/material.dart';

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
      neuralEngine.start();
      neuralEngine.start();
      neuralEngine.stop();
      neuralEngine.stop();
    });

    test('NeuralEngine calculates metrics', () async {
      neuralEngine.start();

      // Feed multiple data points
      for (int i = 0; i < 10; i++) {
        final testData = TongueData(
          timestamp: DateTime.now(),
          position: Offset(0.5 + i * 0.01, 0.5),
          velocity: 1.0 + i * 0.1,
          acceleration: 0.0,
          landmarks: [Offset(0.5 + i * 0.01, 0.5)],
          isValidated: true,
        );
        neuralEngine.processTongueData(testData);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Wait for metrics calculation
      await Future.delayed(const Duration(seconds: 2));

      neuralEngine.stop();
    });

    test('dispose closes resources', () {
      neuralEngine.start();
      neuralEngine.dispose();
      neuralEngine.dispose(); // idempotent
      // Should not throw when stopping after dispose
      neuralEngine.stop();
    });
  });
}
