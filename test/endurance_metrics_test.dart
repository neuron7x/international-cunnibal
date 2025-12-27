import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/core/endurance_metrics.dart';
import 'package:international_cunnibal/core/motion_metrics.dart';

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

void main() {
  group('EnduranceMetrics', () {
    test('zero aperture stays bounded', () {
      final samples = [
        _sample(0.0, 0),
        _sample(0.5, 0),
        _sample(1.0, 0),
      ];
      final result = EnduranceMetrics.compute(samples: samples);
      expect(result.aperture, closeTo(0, 1e-6));
      expect(result.enduranceTime, closeTo(0, 1e-6));
      expect(result.enduranceScore, closeTo(0, 1e-6));
    });

    test('constant aperture yields high stability', () {
      final samples = List.generate(8, (i) => _sample(i * 0.2, 0.22));
      final result = EnduranceMetrics.compute(samples: samples, apertureThreshold: 0.2);
      expect(result.aperture, closeTo(0.22, 1e-4));
      expect(result.apertureStability, greaterThan(95));
      expect(result.enduranceTime, closeTo(1.4, 1e-3));
    });

    test('noise reduces stability', () {
      final rng = Random(2);
      final clean = List.generate(10, (i) => _sample(i * 0.2, 0.25));
      final noisy = List.generate(10, (i) {
        final jitter = (rng.nextDouble() - 0.5) * 0.05;
        return _sample(i * 0.2, (0.25 + jitter).clamp(0.0, 1.0));
      });

      final cleanResult = EnduranceMetrics.compute(samples: clean, apertureThreshold: 0.2);
      final noisyResult = EnduranceMetrics.compute(samples: noisy, apertureThreshold: 0.2);

      expect(noisyResult.apertureStability, lessThan(cleanResult.apertureStability));
    });

    test('threshold inclusivity counts boundary samples', () {
      final samples = [
        _sample(0.0, 0.19),
        _sample(0.5, 0.2),
        _sample(1.0, 0.2),
        _sample(1.5, 0.18),
      ];
      final result = EnduranceMetrics.compute(
        samples: samples,
        apertureThreshold: 0.2,
      );
      expect(result.enduranceTime, closeTo(1.0, 1e-3));
    });

    test('frame rate invariance keeps endurance time stable', () {
      final slow = [
        _sample(0.0, 0.24),
        _sample(0.5, 0.24),
        _sample(1.0, 0.24),
        _sample(1.5, 0.24),
      ];
      final fast = List.generate(13, (i) => _sample(i * 0.125, 0.24));

      final slowResult =
          EnduranceMetrics.compute(samples: slow, apertureThreshold: 0.2);
      final fastResult =
          EnduranceMetrics.compute(samples: fast, apertureThreshold: 0.2);

      expect(fastResult.enduranceTime, closeTo(slowResult.enduranceTime, 0.05));
      expect(fastResult.enduranceScore, closeTo(slowResult.enduranceScore, 5));
    });
  });
}
