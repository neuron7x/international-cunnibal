import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/services/game_logic_service.dart';
import 'package:international_cunnibal/services/neural_engine.dart';
import 'package:international_cunnibal/services/ui/cv_engine.dart';

void main() {
  group('Full disposal lifecycle', () {
    test('complete session start-stop-dispose', () async {
      final cvEngine = DemoCvEngine();
      final neuralEngine = NeuralEngine();
      final gameLogic = GameLogicService();

      await cvEngine.prepare();
      await cvEngine.start();
      neuralEngine.start(enableTimer: false);

      final subscription = cvEngine.stream.listen((data) {
        neuralEngine.processTongueData(data);
      });

      await Future.delayed(const Duration(milliseconds: 200));

      cvEngine.stop();
      neuralEngine.stop();
      await subscription.cancel();

      expect(() {
        cvEngine.dispose();
        neuralEngine.dispose();
        gameLogic.dispose();
      }, returnsNormally);

      expect(() => cvEngine.stream.listen((_) {}), throwsStateError);
      expect(() => neuralEngine.tongueDataStream.listen((_) {}), throwsStateError);
      expect(() => gameLogic.stateStream.listen((_) {}), throwsStateError);
    });
  });
}
