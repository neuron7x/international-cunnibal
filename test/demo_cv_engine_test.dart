import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/services/cv_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DemoCvEngine', () {
    test('emits validated, bounded data', () async {
      final engine = DemoCvEngine();
      await engine.prepare();
      await engine.start();

      final samples = await engine.stream.take(12).toList();
      engine.stop();

      expect(samples, isNotEmpty);
      expect(samples.every((s) => s.isValidated), isTrue);
      expect(
        samples.every((s) => s.position.dx >= 0 && s.position.dx <= 1),
        isTrue,
      );
      expect(
        samples.every((s) => s.position.dy >= 0 && s.position.dy <= 1),
        isTrue,
      );
      expect(samples.every((s) => s.landmarks.length >= 309), isTrue);
      expect(samples.every((s) => s.landmarks[13].dy >= 0), isTrue);
    });
  });
}
