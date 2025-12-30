import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class Landmark {
  final double x;
  final double y;
  final double z;

  const Landmark(this.x, this.y, this.z);
}

class MediaPipeService {
  Interpreter? _interpreter;

  static const int _placeholderSeed = 7;

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

  List<Landmark> detectLandmarks(CameraImage image) {
    if (_interpreter == null) {
      return _placeholderLandmarks();
    }

    // Placeholder output until real preprocessing/inference is wired.
    return _placeholderLandmarks();
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
}
