import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
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

  group('DemoCvEngine edge cases', () {
    test('dispose before start does not throw', () {
      final engine = DemoCvEngine();
      expect(() => engine.dispose(), returnsNormally);
    });

    test('multiple dispose calls are safe', () {
      expect(() {
        final engine = DemoCvEngine();
        engine.dispose();
        engine.dispose();
        engine.dispose();
      }, returnsNormally);
    });

    test('dispose after stop is safe', () async {
      final engine = DemoCvEngine();
      await engine.start();
      engine.stop();
      expect(() => engine.dispose(), returnsNormally);
    });

    test('stream emits data before dispose', () async {
      final engine = DemoCvEngine();
      await engine.start();

      final events = <TongueData>[];
      final subscription = engine.stream.listen(events.add);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(events.length, greaterThan(0));

      engine.dispose();
      await subscription.cancel();
    });
  });
}
