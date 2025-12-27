import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/core/motion_metrics.dart';

MotionSample _sample(double t, double x, double y) =>
    MotionSample(t: t, position: Vector2(x, y));

List<MotionSample> _sineWave({
  required double frequencyHz,
  required double amplitude,
  int samples = 200,
  double dt = 0.01,
  double phase = 0,
}) {
  final twoPiF = 2 * pi * frequencyHz;
  return List.generate(samples, (i) {
    final t = i * dt;
    final x = 0.5 + amplitude * sin(twoPiF * t + phase);
    return _sample(t, x, 0.5);
  });
}

List<MotionSample> _linearMotion({
  required double vx,
  required double vy,
  int samples = 120,
  double dt = 0.01,
}) {
  return List.generate(samples, (i) {
    final t = i * dt;
    return _sample(t, 0.2 + vx * t, 0.3 + vy * t);
  });
}

void main() {
  group('MotionMetrics', () {
    test('zero motion yields zero freq, confidence, intensity', () {
      final samples = List.generate(
        20,
        (i) => _sample(i * 0.02, 0.4, 0.4),
      );
      final metrics = MotionMetrics.compute(
        samples: samples,
        expectedAmplitude: 0.5,
      );
      expect(metrics.frequency.hertz, closeTo(0, 1e-9));
      expect(metrics.frequency.confidence, closeTo(0, 1e-9));
      expect(metrics.intensity, closeTo(0, 1e-9));
    });

    test('consistency is high for constant velocity', () {
      final samples = _linearMotion(vx: 0.05, vy: 0);
      final metrics = MotionMetrics.compute(
        samples: samples,
        expectedAmplitude: 0.5,
      );
      expect(metrics.consistency, greaterThan(95));
    });

    test('consistency drops with noise', () {
      final rng = Random(1);
      final clean = _linearMotion(vx: 0.05, vy: 0);
      final noisy = clean
          .map((s) => MotionSample(
                t: s.t,
                position: Vector2(
                  s.position.x + (rng.nextDouble() - 0.5) * 0.02,
                  s.position.y,
                ),
              ))
          .toList();

      final cleanScore = MotionMetrics.compute(
        samples: clean,
        expectedAmplitude: 0.5,
      ).consistency;
      final noisyScore = MotionMetrics.compute(
        samples: noisy,
        expectedAmplitude: 0.5,
      ).consistency;

      expect(noisyScore, lessThan(cleanScore));
    });

    test('frequency detects dominant sine component', () {
      const freq = 2.0;
      final samples = _sineWave(frequencyHz: freq, amplitude: 0.4);
      final metrics = MotionMetrics.compute(
        samples: samples,
        expectedAmplitude: 0.4,
      );
      expect(metrics.frequency.hertz, closeTo(freq, 0.1));
      expect(metrics.frequency.confidence, greaterThan(0.5));
    });

    test('frequency is not doubled by abs projection', () {
      const freq = 2.0;
      final samples = _sineWave(frequencyHz: freq, amplitude: 0.35);
      final metrics = MotionMetrics.compute(
        samples: samples,
        expectedAmplitude: 0.35,
      );
      expect(metrics.frequency.hertz, closeTo(freq, 0.2));
      expect((metrics.frequency.hertz - 4.0).abs(), greaterThan(1.0));
    });

    test('frequency confidence drops with mixed tones', () {
      final primary = _sineWave(frequencyHz: 2.0, amplitude: 0.3);
      final secondary = _sineWave(
        frequencyHz: 5.0,
        amplitude: 0.15,
        samples: primary.length,
        dt: 0.01,
      );
      final mixed = List.generate(primary.length, (i) {
        return _sample(
          primary[i].t,
          primary[i].position.x + secondary[i].position.x - 0.5,
          0.5,
        );
      });

      final metrics = MotionMetrics.compute(
        samples: mixed,
        expectedAmplitude: 0.3,
      );
      expect(metrics.frequency.hertz, closeTo(2.0, 0.3));
      expect(metrics.frequency.confidence, lessThan(0.7));
    });

    test('direction follows principal axis', () {
      final samples = _linearMotion(vx: 0.04, vy: 0.0);
      final metrics = MotionMetrics.compute(
        samples: samples,
        expectedAmplitude: 0.5,
      );
      expect(metrics.direction.direction.x, closeTo(1, 1e-2));
      expect(metrics.direction.direction.y.abs(), lessThan(1e-2));
      expect(metrics.direction.stability, greaterThan(80));
    });

    test('constant displacement yields stable direction', () {
      final samples = List.generate(
        40,
        (i) => _sample(i * 0.02, 0.2 + 0.01 * i, 0.4),
      );
      final metrics = MotionMetrics.compute(
        samples: samples,
        expectedAmplitude: 0.5,
      );
      expect(metrics.direction.stability, greaterThan(80));
    });

    test('direction respects net motion sign', () {
      final samples = _linearMotion(vx: -0.05, vy: 0.01);
      final metrics = MotionMetrics.compute(
        samples: samples,
        expectedAmplitude: 0.5,
      );
      expect(metrics.direction.direction.x, lessThan(0));
      expect(metrics.direction.direction.y, greaterThan(0));
    });

    test('smooth sine retains stable dominant direction', () {
      final samples = _sineWave(frequencyHz: 2.0, amplitude: 0.35);
      final metrics = MotionMetrics.compute(
        samples: samples,
        expectedAmplitude: 0.35,
      );
      expect(metrics.direction.direction.x.abs(), greaterThan(0.9));
      expect(metrics.direction.direction.y.abs(), lessThan(0.1));
      expect(metrics.direction.stability, greaterThan(65));
    });

    test('random walk yields low consistency and direction stability', () {
      final rng = Random(3);
      final samples = <MotionSample>[];
      var pos = const Vector2(0.5, 0.5);
      for (int i = 0; i < 120; i++) {
        pos = Vector2(
          pos.x + (rng.nextDouble() - 0.5) * 0.02,
          pos.y + (rng.nextDouble() - 0.5) * 0.02,
        );
        samples.add(MotionSample(t: i * 0.01, position: pos));
      }
      final metrics = MotionMetrics.compute(
        samples: samples,
        expectedAmplitude: 0.5,
      );
      expect(metrics.consistency, lessThan(60));
      expect(metrics.direction.stability, lessThan(50));
    });

    test('intensity reflects energy and bounds zero motion', () {
      final stationary = List.generate(
        50,
        (i) => _sample(i * 0.02, 0.3, 0.3),
      );
      final moving = _linearMotion(vx: 0.1, vy: 0.05);

      final zeroIntensity = MotionMetrics.compute(
        samples: stationary,
        expectedAmplitude: 0.5,
      ).intensity;
      final movingIntensity = MotionMetrics.compute(
        samples: moving,
        expectedAmplitude: 0.5,
      ).intensity;

      expect(zeroIntensity, closeTo(0, 1e-6));
      expect(movingIntensity, greaterThan(30));
    });

    test('consistency stays bounded when mean speed is near zero', () {
      final samples = <MotionSample>[];
      var x = 0.5;
      for (var i = 0; i < 60; i++) {
        final dx = i.isEven ? 0.01 : -0.01;
        x += dx;
        samples.add(_sample(i * 0.02, x, 0.5));
      }
      final metrics = MotionMetrics.compute(
        samples: samples,
        expectedAmplitude: 0.5,
      );
      expect(metrics.consistency.isNaN, isFalse);
      expect(metrics.consistency, inInclusiveRange(0, 100));
    });

    test('frequency confidence drops on noise', () {
      final rng = Random(7);
      final samples = <MotionSample>[];
      var pos = const Vector2(0.5, 0.5);
      for (var i = 0; i < 150; i++) {
        pos = Vector2(
          pos.x + (rng.nextDouble() - 0.5) * 0.03,
          pos.y + (rng.nextDouble() - 0.5) * 0.03,
        );
        samples.add(MotionSample(t: i * 0.01, position: pos));
      }
      final metrics = MotionMetrics.compute(
        samples: samples,
        expectedAmplitude: 0.5,
      );
      expect(metrics.frequency.confidence, lessThan(0.3));
    });

    test('pattern match rewards aligned trajectories', () {
      final target = _sineWave(frequencyHz: 1.5, amplitude: 0.3, samples: 60, dt: 0.02);
      final observedSame = _sineWave(frequencyHz: 1.5, amplitude: 0.3, samples: 60, dt: 0.02);
      final observedPhaseShift =
        _sineWave(frequencyHz: 1.5, amplitude: 0.3, samples: 60, dt: 0.02, phase: pi / 2);

      final matched = MotionMetrics.compute(
        samples: observedSame,
        expectedAmplitude: 0.3,
        pattern: target,
        patternTolerance: 0.1,
      ).patternMatch.score;

      final shifted = MotionMetrics.compute(
        samples: observedPhaseShift,
        expectedAmplitude: 0.3,
        pattern: target,
        patternTolerance: 0.1,
      ).patternMatch.score;

      expect(matched, greaterThan(95));
      expect(shifted, lessThan(matched));
    });

    test('pattern tolerance influences score', () {
      final target = _sineWave(frequencyHz: 1.0, amplitude: 0.25, samples: 50, dt: 0.02);
      final slightlyOff = _sineWave(
        frequencyHz: 1.0,
        amplitude: 0.3,
        samples: 50,
        dt: 0.02,
        phase: 0.1,
      );

      final strict = MotionMetrics.compute(
        samples: slightlyOff,
        expectedAmplitude: 0.25,
        pattern: target,
        patternTolerance: 0.05,
      ).patternMatch.score;

      final loose = MotionMetrics.compute(
        samples: slightlyOff,
        expectedAmplitude: 0.25,
        pattern: target,
        patternTolerance: 0.2,
      ).patternMatch.score;

      expect(loose, greaterThan(strict));
    });

    test('metrics are deterministic and bounded', () {
      final samples = _sineWave(frequencyHz: 1.2, amplitude: 0.35, samples: 80, dt: 0.02);
      final first = MotionMetrics.compute(
        samples: samples,
        expectedAmplitude: 0.35,
      );
      final second = MotionMetrics.compute(
        samples: samples,
        expectedAmplitude: 0.35,
      );

      expect(first.consistency, closeTo(second.consistency, 1e-9));
      expect(first.frequency.hertz, closeTo(second.frequency.hertz, 1e-9));
      expect(first.intensity, closeTo(second.intensity, 1e-9));
      expect(first.patternMatch.score, closeTo(second.patternMatch.score, 1e-9));

      expect(first.consistency, inInclusiveRange(0, 100));
      expect(first.direction.stability, inInclusiveRange(0, 100));
      expect(first.intensity, inInclusiveRange(0, 100));
      expect(first.patternMatch.score, inInclusiveRange(0, 100));
    });

    test('pattern match stays bounded for short targets', () {
      final observed = _sineWave(frequencyHz: 1.2, amplitude: 0.2, samples: 30, dt: 0.04);
      final target = _sineWave(frequencyHz: 1.2, amplitude: 0.2, samples: 3, dt: 0.04);

      final metrics = MotionMetrics.compute(
        samples: observed,
        expectedAmplitude: 0.2,
        pattern: target,
        patternTolerance: 0.1,
      );

      expect(metrics.patternMatch.score, inInclusiveRange(0, 100));
      expect(metrics.patternMatch.mse, greaterThanOrEqualTo(0));
    });
  });
}
