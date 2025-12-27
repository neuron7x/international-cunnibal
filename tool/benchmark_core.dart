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
  for (int i = 0; i < 200; i++) {
    MotionMetrics.compute(samples: samples, expectedAmplitude: 0.3);
  }
  watch.stop();

  final perRunUs = watch.elapsedMicroseconds / 200;
  // ignore: avoid_print
  print(
    'BENCHMARK motion_metrics iterations=200 '
    'total_ms=${watch.elapsedMilliseconds} '
    'per_run_us=${perRunUs.toStringAsFixed(1)}',
  );
}
