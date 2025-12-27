import 'dart:math';
import 'package:international_cunnibal/core/motion_metrics.dart';

Future<void> main() async {
  final samples = List.generate(240, (i) {
    final t = i * 0.016;
    return MotionSample(
      t: t,
      position: Vector2(
        0.5 + sin(i / 30) * 0.2,
        0.5 + cos(i / 20) * 0.1,
      ),
    );
  });

  final watch = Stopwatch()..start();
  const iterations = 200;
  for (int i = 0; i < iterations; i++) {
    MotionMetrics.compute(samples: samples, expectedAmplitude: 0.3);
  }
  watch.stop();

  final perRunUs = watch.elapsedMicroseconds / iterations;
  // ignore: avoid_print
  print('MEAN_US=${perRunUs.toStringAsFixed(1)}');
}
