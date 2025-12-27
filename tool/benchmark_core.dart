import 'dart:math';
import 'package:flutter/material.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/services/signal_processor.dart';

Future<void> main() async {
  final processor = SignalProcessor();
  final now = DateTime.now();
  final buffer = List.generate(240, (i) {
    return TongueData(
      timestamp: now.add(Duration(milliseconds: i * 16)),
      position: Offset(0.5 + sin(i / 30) * 0.2, 0.5 + cos(i / 20) * 0.1),
      velocity: 1.0 + sin(i / 10),
      acceleration: 0,
      landmarks: const [Offset(0.5, 0.5)],
      isValidated: true,
    );
  });

  final watch = Stopwatch()..start();
  for (int i = 0; i < 200; i++) {
    processor.calculate(buffer);
  }
  watch.stop();

  final perRunUs = watch.elapsedMicroseconds / 200;
  // ignore: avoid_print
  print('Processed 200 iterations in ${watch.elapsedMilliseconds}ms '
      '(~${perRunUs.toStringAsFixed(1)}µs per run)');
}
