import 'dart:async';
import 'package:international_cunnibal/core/motion_metrics.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/services/cv_engine.dart';

Future<void> main() async {
  final engine = DemoCvEngine();
  final buffer = <TongueData>[];

  await engine.prepare();
  await engine.start();

  final subscription = engine.stream.listen((sample) {
    buffer.add(sample);
    if (buffer.length > 120) buffer.removeAt(0);
    final metrics = MotionMetrics.compute(
      samples: buffer
          .map((t) => MotionSample(
                t: t.timestamp.millisecondsSinceEpoch / 1000.0,
                position: Vector2(t.position.dx, t.position.dy),
              ))
          .toList(),
      expectedAmplitude: 0.4,
    );
    // ignore: avoid_print
    print(metrics);
  });

  await Future.delayed(const Duration(seconds: 3));
  await subscription.cancel();
  engine.stop();
}
