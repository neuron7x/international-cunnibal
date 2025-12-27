import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/services/signal_processor.dart';

void main() {
  group('SignalProcessor', () {
    final processor = SignalProcessor();

    List<TongueData> _buildBuffer({
      required List<double> velocities,
      required List<Offset> positions,
      DateTime? start,
    }) {
      final startTime = start ?? DateTime.now();
      return List.generate(velocities.length, (i) {
        return TongueData(
          timestamp: startTime.add(Duration(milliseconds: i * 100)),
          position: positions[i],
          velocity: velocities[i],
          acceleration: 0,
          landmarks: const [Offset(0.5, 0.5)],
          isValidated: true,
        );
      });
    }

    test('returns high consistency for steady velocity', () {
      final buffer = _buildBuffer(
        velocities: List.filled(8, 1.0),
        positions: List.generate(8, (i) => Offset(0.4 + i * 0.01, 0.5)),
      );

      final metrics = processor.calculate(buffer);

      expect(metrics.consistencyScore, greaterThan(80));
    });

    test('detects dominant direction', () {
      final buffer = _buildBuffer(
        velocities: List.filled(6, 1.2),
        positions: const [
          Offset(0.2, 0.5),
          Offset(0.3, 0.5),
          Offset(0.4, 0.5),
          Offset(0.5, 0.5),
          Offset(0.6, 0.5),
          Offset(0.7, 0.5),
        ],
      );

      final metrics = processor.calculate(buffer);

      expect(metrics.movementDirection, MovementDirection.right);
      expect(metrics.directionStability, greaterThan(0));
    });

    test('calculates non-zero frequency for oscillating velocity', () {
      final buffer = _buildBuffer(
        velocities: const [0.1, 0.9, 0.2, 1.0, 0.3, 1.1, 0.2],
        positions: List.generate(7, (i) => Offset(0.5, 0.5 + (i * 0.01))),
      );

      final metrics = processor.calculate(buffer);
      expect(metrics.frequency, greaterThan(0));
    });
  });
}
