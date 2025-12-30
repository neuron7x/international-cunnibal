import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/services/ui/cv_engine.dart';

const int _disposeBudgetMicros = 1000;

void main() {
  test('dispose performance benchmark', () async {
    const iterations = 100;
    final stopwatch = Stopwatch();

    final engines = List.generate(iterations, (_) => DemoCvEngine());

    for (final engine in engines) {
      await engine.start();
    }

    stopwatch.start();
    for (final engine in engines) {
      engine.dispose();
    }
    stopwatch.stop();

    final avgDispose = stopwatch.elapsedMicroseconds / iterations;

    expect(avgDispose, lessThan(_disposeBudgetMicros));
  });
}
