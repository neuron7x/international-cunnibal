import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/dictation_session.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:flutter/material.dart';

void main() {
  group('TongueData Model Tests', () {
    test('TongueData creates correctly', () {
      final data = TongueData(
        timestamp: DateTime.now(),
        position: const Offset(0.5, 0.5),
        velocity: 1.0,
        acceleration: 0.0,
        landmarks: [const Offset(0.5, 0.5)],
        isValidated: true,
      );

      expect(data.position.dx, equals(0.5));
      expect(data.velocity, equals(1.0));
      expect(data.isValidated, equals(true));
    });

    test('TongueData copyWith works correctly', () {
      final data = TongueData(
        timestamp: DateTime.now(),
        position: const Offset(0.5, 0.5),
        velocity: 1.0,
        acceleration: 0.0,
        landmarks: [const Offset(0.5, 0.5)],
        isValidated: true,
      );

      final updated = data.copyWith(velocity: 2.0, isValidated: false);

      expect(updated.velocity, equals(2.0));
      expect(updated.isValidated, equals(false));
      expect(updated.position, equals(data.position));
    });

    test('TongueData serializes to JSON', () {
      final data = TongueData(
        timestamp: DateTime(2025, 12, 26),
        position: const Offset(0.5, 0.5),
        velocity: 1.0,
        acceleration: 0.0,
        landmarks: [const Offset(0.5, 0.5)],
        isValidated: true,
      );

      final json = data.toJson();

      expect(json['velocity'], equals(1.0));
      expect(json['isValidated'], equals(true));
      expect(json['position']['x'], equals(0.5));
    });
  });

  group('BiometricMetrics Model Tests', () {
    test('BiometricMetrics creates correctly', () {
      final metrics = BiometricMetrics(
        consistencyScore: 85.0,
        frequency: 2.5,
        frequencyConfidence: 0.8,
        pcaVariance: [60.0, 30.0, 10.0],
        movementDirection: MovementDirection.right,
        directionStability: 40,
        intensity: 55,
        patternScore: 70,
        endurance: EnduranceSnapshot.empty(),
        timestamp: DateTime.now(),
      );

      expect(metrics.consistencyScore, equals(85.0));
      expect(metrics.frequency, equals(2.5));
      expect(metrics.pcaVariance.length, equals(3));
    });

    test('BiometricMetrics serializes to JSON', () {
      final metrics = BiometricMetrics(
        consistencyScore: 85.0,
        frequency: 2.5,
        frequencyConfidence: 0.6,
        pcaVariance: [60.0, 30.0, 10.0],
        movementDirection: MovementDirection.left,
        directionStability: 25,
        intensity: 30,
        patternScore: 10,
        endurance: const EnduranceSnapshot(
          aperture: 0.2,
          apertureStability: 70,
          fatigueIndicator: 10,
          enduranceTime: 1.5,
          enduranceScore: 80,
          threshold: 0.18,
        ),
        timestamp: DateTime(2025, 12, 26),
      );

      final json = metrics.toJson();

      expect(json['consistencyScore'], equals(85.0));
      expect(json['frequency'], equals(2.5));
      expect(json['frequencyConfidence'], equals(0.6));
      expect(json['pcaVariance'], equals([60.0, 30.0, 10.0]));
      expect(json['endurance']['enduranceScore'], equals(80));
    });
  });

  group('DictationSession Model Tests', () {
    test('DictationSession creates correctly', () {
      final session = DictationSession(
        targetSymbol: 'A',
        startTime: DateTime.now(),
        rhythmTimestamps: [0.0, 0.5, 1.0],
        synchronizationScore: 75.0,
      );

      expect(session.targetSymbol, equals('A'));
      expect(session.rhythmTimestamps.length, equals(3));
      expect(session.synchronizationScore, equals(75.0));
    });

    test('DictationSession calculates rhythm consistency', () {
      final session = DictationSession(
        targetSymbol: 'A',
        startTime: DateTime.now(),
        rhythmTimestamps: [0.0, 0.5, 1.0, 1.5],
        synchronizationScore: 75.0,
      );

      // Should have high consistency for evenly spaced timestamps
      expect(session.rhythmConsistency, greaterThan(50.0));
    });

    test('DictationSession serializes to JSON', () {
      final session = DictationSession(
        targetSymbol: 'A',
        startTime: DateTime(2025, 12, 26),
        rhythmTimestamps: [0.0, 0.5, 1.0],
        synchronizationScore: 75.0,
      );

      final json = session.toJson();

      expect(json['targetSymbol'], equals('A'));
      expect(json['synchronizationScore'], equals(75.0));
      expect(json['rhythmTimestamps'], equals([0.0, 0.5, 1.0]));
    });
  });
}
