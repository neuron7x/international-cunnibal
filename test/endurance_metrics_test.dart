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
    test('empty samples return zeros', () {
      final result = EnduranceMetrics.compute(samples: const []);
      expect(result.aperture, equals(0));
      expect(result.enduranceScore, equals(0));
      expect(result.apertureStability, equals(0));
    });

    test('short samples return zeros', () {
      final result = EnduranceMetrics.compute(samples: [_sample(0.0, 0.2)]);
      expect(result.aperture, equals(0));
      expect(result.enduranceScore, equals(0));
      expect(result.apertureStability, equals(0));
    });

    test('zero aperture stays bounded', () {
      final samples = [
        _sample(0.0, 0),
        _sample(0.5, 0),
        _sample(1.0, 0),
      ];
      final result = EnduranceMetrics.compute(samples: samples);
      expect(result.aperture, closeTo(0, 1e-6));
      expect(result.enduranceTime, closeTo(0, 1e-6));
      expect(result.fatigueIndicator, closeTo(0, 1e-6));
      expect(result.enduranceScore, closeTo(0, 1e-6));
    });

    test('constant aperture yields high stability', () {
      final samples = List.generate(8, (i) => _sample(i * 0.2, 0.22));
      final result = EnduranceMetrics.compute(samples: samples, apertureThreshold: 0.2);
      expect(result.aperture, closeTo(0.22, 1e-4));
      expect(result.apertureStability, greaterThan(95));
      expect(result.enduranceTime, closeTo(1.4, 1e-3));
      expect(result.fatigueIndicator, closeTo(0, 1e-6));
      expect(result.enduranceScore, closeTo(80.5, 1e-2));
    });

    test('aperture clamps to configured max', () {
      final samples = List.generate(6, (i) => _sample(i * 0.2, 0.8));
      final result = EnduranceMetrics.compute(
        samples: samples,
        apertureThreshold: 0.2,
        apertureMax: 0.4,
      );
      expect(result.aperture, lessThanOrEqualTo(0.4));
      expect(result.enduranceScore, inInclusiveRange(0, 100));
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

    test('fatigue detects stability degradation', () {
      final samples = [
        _sample(0.0, 0.22),
        _sample(0.2, 0.22),
        _sample(0.4, 0.22),
        _sample(0.6, 0.22),
        _sample(0.8, 0.20),
        _sample(1.0, 0.24),
        _sample(1.2, 0.20),
        _sample(1.4, 0.24),
      ];
      final result = EnduranceMetrics.compute(samples: samples, apertureThreshold: 0.2);
      expect(result.fatigueIndicator, closeTo(9.09, 0.1));
      expect(result.apertureStability, lessThan(100));
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

    test('no NaN or Inf propagation on degenerate input', () {
      const sample = ApertureSample(
        t: 0,
        upperLip: Vector2(0.5, 0.5),
        lowerLip: Vector2(0.5, 0.5),
        leftCorner: Vector2(0.5, 0.5),
        rightCorner: Vector2(0.5, 0.5),
      );
      final result = EnduranceMetrics.compute(samples: [sample, sample]);
      expect(result.aperture.isNaN, isFalse);
      expect(result.aperture.isInfinite, isFalse);
      expect(result.enduranceScore.isNaN, isFalse);
      expect(result.enduranceScore.isInfinite, isFalse);
    });

    test('deterministic output for identical input', () {
      final samples = List.generate(6, (i) => _sample(i * 0.3, 0.23));
      final first = EnduranceMetrics.compute(samples: samples, apertureThreshold: 0.2);
      final second = EnduranceMetrics.compute(samples: samples, apertureThreshold: 0.2);
      expect(first.enduranceScore, closeTo(second.enduranceScore, 1e-6));
      expect(first.fatigueIndicator, closeTo(second.fatigueIndicator, 1e-6));
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

    test('step function apertures remain bounded', () {
      final samples = <ApertureSample>[];
      for (var i = 0; i < 10; i++) {
        final value = i < 5 ? 0.15 : 0.3;
        samples.add(_sample(i * 0.2, value));
      }
      final result = EnduranceMetrics.compute(
        samples: samples,
        apertureThreshold: 0.2,
      );
      expect(result.aperture, inInclusiveRange(0, 1));
      expect(result.apertureStability, inInclusiveRange(0, 100));
      expect(result.enduranceScore, inInclusiveRange(0, 100));
    });

    test('alternating apertures stay deterministic', () {
      final samples = List.generate(
        12,
        (i) => _sample(i * 0.2, i.isEven ? 0.18 : 0.26),
      );
      final first = EnduranceMetrics.compute(samples: samples, apertureThreshold: 0.2);
      final second = EnduranceMetrics.compute(samples: samples, apertureThreshold: 0.2);
      expect(first.aperture, closeTo(second.aperture, 1e-9));
      expect(first.enduranceScore, closeTo(second.enduranceScore, 1e-9));
    });

    test('scaled apertures stay within bounds', () {
      final base = List.generate(8, (i) => _sample(i * 0.2, 0.2));
      final scaled = List.generate(8, (i) => _sample(i * 0.2, 0.4));
      final baseResult = EnduranceMetrics.compute(samples: base, apertureThreshold: 0.2);
      final scaledResult =
          EnduranceMetrics.compute(samples: scaled, apertureThreshold: 0.2);
      expect(baseResult.aperture, inInclusiveRange(0, 1));
      expect(scaledResult.aperture, inInclusiveRange(0, 1));
      expect(baseResult.enduranceScore, inInclusiveRange(0, 100));
      expect(scaledResult.enduranceScore, inInclusiveRange(0, 100));
    });

    test('noisy deterministic series stays finite', () {
      final rng = Random(9);
      final samples = List.generate(12, (i) {
        final jitter = (rng.nextDouble() - 0.5) * 0.04;
        return _sample(i * 0.2, (0.22 + jitter).clamp(0.0, 1.0));
      });
      final result = EnduranceMetrics.compute(samples: samples, apertureThreshold: 0.2);
      expect(result.aperture.isNaN, isFalse);
      expect(result.apertureStability.isNaN, isFalse);
      expect(result.enduranceScore.isNaN, isFalse);
      expect(result.apertureStability, inInclusiveRange(0, 100));
      expect(result.enduranceScore, inInclusiveRange(0, 100));
    });
  });
}
