import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:international_cunnibal/services/motion_validation_controller.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/utils/constants.dart';

void main() {
  group('MotionValidationController', () {
    late MotionValidationController controller;

    setUp(() {
      controller = MotionValidationController();
      controller.reset();
    });

    tearDown(() {
      controller.dispose();
    });

    group('Basic Validation', () {
      test('first measurement is always valid', () {
        final data = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 10.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        final validated = controller.validate(data);

        expect(validated.isValidated, true,
            reason: 'First measurement should be valid (no previous data)');
      });

      test('validates consistent velocity changes', () {
        final data1 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 10.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        final data2 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.52, 0.5),
          velocity: 12.0, // Small velocity change (2.0 < threshold)
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        controller.validate(data1);
        final validated = controller.validate(data2);

        expect(validated.isValidated, true,
            reason: 'Small velocity change should be valid');
      });

      test('detects inconsistent velocity changes', () {
        final data1 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 10.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        final data2 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.8, 0.5),
          velocity: 200.0, // Large velocity change (190.0 > threshold)
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        controller.validate(data1);
        final validated = controller.validate(data2);

        expect(validated.isValidated, false,
            reason: 'Large velocity change should be invalid');
      });

      test('validates exactly at threshold boundary', () {
        final threshold = NeuralEngineConstants.velocityChangeThreshold;

        final data1 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 10.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        final data2 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.52, 0.5),
          velocity: 10.0 + threshold - 0.1, // Just below threshold
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        controller.validate(data1);
        final validated = controller.validate(data2);

        expect(validated.isValidated, true,
            reason: 'Velocity change just below threshold should be valid');
      });
    });

    group('Validation Statistics', () {
      test('tracks total validations', () {
        final baseData = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 10.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        for (int i = 0; i < 10; i++) {
          controller.validate(baseData.copyWith(velocity: 10.0 + i * 0.5));
        }

        final metrics = controller.getMetrics();
        expect(metrics.totalValidations, 10,
            reason: 'Should track total validation count');
      });

      test('tracks valid and invalid counts separately', () {
        final data1 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 10.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        // Valid changes
        controller.validate(data1);
        controller.validate(data1.copyWith(velocity: 11.0));
        controller.validate(data1.copyWith(velocity: 12.0));

        // Invalid change
        controller.validate(data1.copyWith(velocity: 200.0));

        // More valid changes
        controller.validate(data1.copyWith(velocity: 205.0));
        controller.validate(data1.copyWith(velocity: 206.0));

        final metrics = controller.getMetrics();
        expect(metrics.totalValidations, 6);
        expect(metrics.validCount, 5,
            reason: 'Should have 5 valid measurements');
        expect(metrics.invalidCount, 1,
            reason: 'Should have 1 invalid measurement');
      });

      test('calculates validation rate correctly', () {
        final data1 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 10.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        // 7 valid, 3 invalid = 70% validation rate
        controller.validate(data1); // valid
        controller.validate(data1.copyWith(velocity: 11.0)); // valid
        controller.validate(data1.copyWith(velocity: 200.0)); // invalid
        controller.validate(data1.copyWith(velocity: 205.0)); // valid
        controller.validate(data1.copyWith(velocity: 206.0)); // valid
        controller.validate(data1.copyWith(velocity: 400.0)); // invalid
        controller.validate(data1.copyWith(velocity: 405.0)); // valid
        controller.validate(data1.copyWith(velocity: 406.0)); // valid
        controller.validate(data1.copyWith(velocity: 600.0)); // invalid
        controller.validate(data1.copyWith(velocity: 605.0)); // valid

        final metrics = controller.getMetrics();
        expect(metrics.validationRate, closeTo(0.7, 0.01),
            reason: 'Validation rate should be 70%');
      });

      test('handles zero validations', () {
        final metrics = controller.getMetrics();
        expect(metrics.totalValidations, 0);
        expect(metrics.validCount, 0);
        expect(metrics.invalidCount, 0);
        expect(metrics.validationRate, 0.0,
            reason: 'Validation rate should be 0 with no validations');
      });
    });

    group('State Management', () {
      test('reset clears all statistics', () {
        final data = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 10.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        // Perform some validations
        controller.validate(data);
        controller.validate(data.copyWith(velocity: 11.0));
        controller.validate(data.copyWith(velocity: 200.0));

        // Reset
        controller.reset();

        final metrics = controller.getMetrics();
        expect(metrics.totalValidations, 0,
            reason: 'Reset should clear validation count');
        expect(metrics.validCount, 0,
            reason: 'Reset should clear valid count');
        expect(metrics.invalidCount, 0,
            reason: 'Reset should clear invalid count');
      });

      test('reset allows fresh validation after reset', () {
        final data = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 10.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        // Initial validations
        controller.validate(data);
        controller.validate(data.copyWith(velocity: 200.0));

        // Reset
        controller.reset();

        // First validation after reset should be valid (no previous data)
        final validated = controller.validate(data);
        expect(validated.isValidated, true,
            reason: 'First validation after reset should be valid');
      });
    });

    group('Deterministic Behavior', () {
      test('same inputs produce same outputs', () {
        final data1 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 10.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        final data2 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.52, 0.5),
          velocity: 15.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        // First run
        controller.reset();
        controller.validate(data1);
        final result1 = controller.validate(data2);

        // Second run with same inputs
        controller.reset();
        controller.validate(data1);
        final result2 = controller.validate(data2);

        expect(result1.isValidated, result2.isValidated,
            reason: 'Same inputs should produce same validation result');
      });
    });

    group('Edge Cases', () {
      test('handles zero velocity correctly', () {
        final data1 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 0.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        final data2 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 0.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        controller.validate(data1);
        final validated = controller.validate(data2);

        expect(validated.isValidated, true,
            reason: 'Zero velocity change should be valid');
      });

      test('handles negative velocity correctly', () {
        final data1 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: -10.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        final data2 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.48, 0.5),
          velocity: -12.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        controller.validate(data1);
        final validated = controller.validate(data2);

        expect(validated.isValidated, true,
            reason: 'Small negative velocity change should be valid');
      });

      test('handles velocity sign change correctly', () {
        final data1 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 10.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        final data2 = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.48, 0.5),
          velocity: -10.0, // Sign change
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        controller.validate(data1);
        final validated = controller.validate(data2);

        // Velocity change is |(-10) - 10| = 20, which should be < threshold (100)
        expect(validated.isValidated, true,
            reason: 'Small velocity sign change should be valid');
      });
    });

    group('Metrics Stream', () {
      test('emits metrics periodically', () async {
        final data = TongueData(
          timestamp: DateTime.now(),
          position: const Offset(0.5, 0.5),
          velocity: 10.0,
          acceleration: 0.0,
          landmarks: [],
          isValidated: false,
        );

        final metricsReceived = <ValidationMetrics>[];
        final subscription = controller.metricsStream.listen((metrics) {
          metricsReceived.add(metrics);
        });

        // Perform 30 validations to trigger metrics emission
        for (int i = 0; i < 30; i++) {
          controller.validate(data.copyWith(velocity: 10.0 + i * 0.1));
        }

        // Wait for stream to process
        await Future.delayed(const Duration(milliseconds: 100));

        expect(metricsReceived.isNotEmpty, true,
            reason: 'Should emit metrics after 30 validations');

        await subscription.cancel();
      });
    });

    group('ValidationMetrics', () {
      test('converts to JSON correctly', () {
        final metrics = ValidationMetrics(
          totalValidations: 100,
          validCount: 85,
          invalidCount: 15,
          validationRate: 0.85,
          timestamp: DateTime(2025, 12, 30, 12, 0, 0),
        );

        final json = metrics.toJson();

        expect(json['totalValidations'], 100);
        expect(json['validCount'], 85);
        expect(json['invalidCount'], 15);
        expect(json['validationRate'], 0.85);
        expect(json['timestamp'], isNotNull);
      });

      test('toString provides readable format', () {
        final metrics = ValidationMetrics(
          totalValidations: 100,
          validCount: 85,
          invalidCount: 15,
          validationRate: 0.85,
          timestamp: DateTime.now(),
        );

        final string = metrics.toString();

        expect(string, contains('100'));
        expect(string, contains('85'));
        expect(string, contains('15'));
        expect(string, contains('85.0%'));
      });
    });
  });
}
