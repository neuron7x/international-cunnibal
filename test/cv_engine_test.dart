import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/services/cv_engine.dart';

void main() {
  group('DemoCvEngine lifecycle', () {
    test('start/stop is idempotent', () async {
      final engine = DemoCvEngine();
      await engine.prepare();
      await engine.start();
      await engine.start();
      engine.stop();
      engine.stop();
    });
  });

  group('CameraCvEngine lifecycle (no camera required)', () {
    test('stop without start does not throw', () {
      final engine = CameraCvEngine();
      engine.stop();
    });
  });
}
