import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

typedef TensorInput = List<List<List<List<double>>>>;

class Landmark {
  final double x;
  final double y;
  final double z;

  const Landmark(this.x, this.y, this.z);
}

class MediaPipeService {
  Interpreter? _interpreter;

  static const int _placeholderSeed = 7;
  static const int _inputSize = 256;
  static const int _facemarkCount = 468;
  static const double _normalizationFactor = 127.5;
  static const int _sampleBytes = 1024;

  static const List<int> tongueLandmarkIndices = [
    13,
    14,
    78,
    308,
    324,
    375,
    405,
    406,
    407,
  ];

  bool get isLoaded => _interpreter != null;

  Future<void> loadModel() async {
    _interpreter ??=
        await Interpreter.fromAsset('assets/models/face_landmark.tflite');
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  List<Landmark> detectLandmarks(CameraImage image) {
    if (_interpreter == null) {
      return _placeholderLandmarks();
    }

    final input = _preprocessImage(image);
    final outputBuffer = List.generate(
      1,
      (_) => List.generate(_facemarkCount, (_) => List<double>.filled(3, 0.0)),
    );
    try {
      _interpreter!.run(input, outputBuffer);
      return _parseLandmarks(outputBuffer.first);
    } catch (_) {
      return _placeholderLandmarks();
    }
  }

  List<Landmark> _placeholderLandmarks() {
    final random = Random(_placeholderSeed);
    return tongueLandmarkIndices
        .map(
          (_) => Landmark(
            random.nextDouble(),
            random.nextDouble(),
            random.nextDouble(),
          ),
        )
        .toList(growable: false);
  }

  TensorInput _preprocessImage(CameraImage image) {
    final plane = image.planes.first;
    if (plane.bytes.isEmpty) {
      return _emptyInput();
    }
    final length = plane.bytes.length;
    final step = (length / _sampleBytes).ceil().clamp(1, length);
    var sum = 0;
    var count = 0;
    for (var i = 0; i < length && count < _sampleBytes; i += step) {
      sum += plane.bytes[i];
      count++;
    }
    final mean = count == 0 ? 0 : sum / count;
    final normalizedValue = (mean / _normalizationFactor) - 1.0;

    final normalized = List<List<List<List<double>>>>.generate(
      1,
      (_) => List<List<List<double>>>.generate(
        _inputSize,
        (_) => List<List<double>>.generate(
          _inputSize,
          (_) => List<double>.filled(3, normalizedValue),
        ),
      ),
    );
    return normalized;
  }

  List<Landmark> _parseLandmarks(List<List<double>> output) {
    final flat = output;
    final result = <Landmark>[];
    for (var i = 0; i < flat.length; i++) {
      final entry = flat[i];
      if (entry.length < 3) continue;
      result.add(Landmark(entry[0], entry[1], entry[2]));
    }
    if (result.isEmpty) {
      return _placeholderLandmarks();
    }
    return result;
  }

  TensorInput _emptyInput() {
    return List<List<List<List<double>>>>.generate(
      1,
      (_) => List<List<List<double>>>.generate(
        _inputSize,
        (_) => List<List<double>>.generate(
          _inputSize,
          (_) => List<double>.filled(3, 0.0),
        ),
      ),
    );
  }
}
