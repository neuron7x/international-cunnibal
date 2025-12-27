import 'dart:async';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/services/cv_engine.dart';
import 'package:international_cunnibal/services/signal_processor.dart';

Future<void> main() async {
  final engine = DemoCvEngine();
  final processor = SignalProcessor();
  final buffer = <TongueData>[];

  await engine.prepare();
  await engine.start();

  final subscription = engine.stream.listen((sample) {
    buffer.add(sample);
    if (buffer.length > 120) buffer.removeAt(0);
    final metrics = processor.calculate(buffer);
    // ignore: avoid_print
    print(metrics);
  });

  await Future.delayed(const Duration(seconds: 3));
  await subscription.cancel();
  engine.stop();
}
