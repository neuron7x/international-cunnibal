import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/services/ui/cv_engine.dart';

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

    test('dispose closes stream controller', () async {
      final engine = DemoCvEngine();
      await engine.start();

      final subscription = engine.stream.listen((_) {});
      expect(engine.isActive, isTrue);

      engine.dispose();

      expect(() => engine.stream.listen((_) {}), throwsStateError);
      await subscription.cancel();
    });

    test('dispose is idempotent', () {
      final engine = DemoCvEngine();
      expect(() {
        engine.dispose();
        engine.dispose();
      }, returnsNormally);
    });
  });

  group('CameraCvEngine lifecycle (no camera required)', () {
    test('stop without start does not throw', () {
      final engine = CameraCvEngine();
      engine.stop();
    });
  });
}
