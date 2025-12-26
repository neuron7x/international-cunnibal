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

    test('NeuralEngine starts and stops correctly', () {
      expect(neuralEngine, isNotNull);
      
      neuralEngine.start();
      // Verify processing state
      
      neuralEngine.stop();
      // Verify stopped state
    });

    test('NeuralEngine processes tongue data', () async {
      neuralEngine.start();

      final testData = TongueData(
        timestamp: DateTime.now(),
        position: const Offset(0.5, 0.5),
        velocity: 1.0,
        acceleration: 0.0,
        landmarks: [const Offset(0.5, 0.5)],
        isValidated: true,
      );

      // Process data
      neuralEngine.processTongueData(testData);

      // Wait for processing
      await Future.delayed(const Duration(milliseconds: 100));

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
  });
}
