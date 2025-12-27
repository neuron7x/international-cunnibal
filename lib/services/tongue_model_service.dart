import 'package:tflite_flutter/tflite_flutter.dart';

class TongueModelService {
  Interpreter? _interpreter;

  bool get isLoaded => _interpreter != null;

  Future<bool> loadModel({
    String assetPath = 'assets/models/tongue_detector.tflite',
  }) async {
    if (isLoaded) return true;
    try {
      _interpreter = await Interpreter.fromAsset(assetPath);
      return true;
    } catch (_) {
      _interpreter = null;
      return false;
    }
  }

  Future<Duration?> warmup({int runs = 3}) async {
    if (!isLoaded) return null;
    final interpreter = _interpreter;
    if (interpreter == null) return null;

    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);

    final input = _buildTensor(inputTensor.shape, 0.0);
    final output = _buildTensor(outputTensor.shape, 0.0);

    final watch = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      interpreter.run(input, output);
    }
    watch.stop();
    return Duration(microseconds: watch.elapsedMicroseconds ~/ runs);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  dynamic _buildTensor(List<int> shape, double value) {
    if (shape.isEmpty) return value;
    if (shape.length == 1) {
      return List<double>.filled(shape.first, value);
    }
    return List.generate(
      shape.first,
      (_) => _buildTensor(shape.sublist(1), value),
    );
  }
}
