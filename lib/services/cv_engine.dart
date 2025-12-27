import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/utils/constants.dart';

enum CvEngineMode { demo, camera }

const double _demoJitterAmplitude = 0.01;
const int _demoLandmarkCount = 8;
const int _cameraLandmarkCount = 10;
const int _cameraLandmarkCenterOffset = 5;
const int _cameraLandmarkRowSize = 3;
const double _cameraLandmarkSpread = 0.01;

abstract class CvEngine {
  Stream<TongueData> get stream;
  CameraController? get cameraController => null;
  bool get isActive;

  Future<void> prepare();
  Future<void> start();
  void stop();
}

class DemoCvEngine implements CvEngine {
  final StreamController<TongueData> _controller =
      StreamController<TongueData>.broadcast();
  Timer? _timer;
  int _frame = 0;
  Offset _lastPosition = const Offset(0.5, 0.5);
  double _lastVelocity = 0;
  final Random _random = Random();

  @override
  bool get isActive => _timer != null;

  @override
  Stream<TongueData> get stream => _controller.stream;

  @override
  Future<void> prepare() async {}

  @override
  Future<void> start() async {
    if (isActive) return;
    _timer = Timer.periodic(
      const Duration(milliseconds: BioTrackingConstants.frameProcessingIntervalMs),
      (_) {
        _frame++;
        _controller.add(_nextSample());
      },
    );
  }

  TongueData _nextSample() {
    final time = _frame / BioTrackingConstants.framesPerSecond;
    final xWave = sin(time * 1.2) * BioTrackingConstants.simulationAmplitudeX;
    final yWave =
        cos(time * BioTrackingConstants.simulationFrequencyMultiplier) *
            BioTrackingConstants.simulationAmplitudeY;
    final jitter = (_random.nextDouble() - 0.5) * _demoJitterAmplitude;

    final position = Offset(
      (0.5 + xWave + jitter).clamp(0.1, 0.9),
      (0.5 + yWave - jitter).clamp(0.1, 0.9),
    );

    final velocity =
        (position - _lastPosition).distance * BioTrackingConstants.framesPerSecond;
    final acceleration =
        (velocity - _lastVelocity) * BioTrackingConstants.framesPerSecond;

    _lastPosition = position;
    _lastVelocity = velocity;

    final timeShift = time * 0.8;
    final landmarks = List<Offset>.generate(
      _demoLandmarkCount,
      (i) => Offset(
        position.dx + cos(timeShift + i) * _demoJitterAmplitude,
        position.dy + sin(timeShift + i) * _demoJitterAmplitude,
      ),
    );

    return TongueData(
      timestamp: DateTime.now(),
      position: position,
      velocity: velocity,
      acceleration: acceleration,
      landmarks: landmarks,
      isValidated: true,
    );
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

class CameraCvEngine implements CvEngine {
  CameraController? _controller;
  final StreamController<TongueData> _stream =
      StreamController<TongueData>.broadcast();
  Timer? _timer;
  int _frame = 0;
  Offset _lastPosition = Offset.zero;
  double _lastVelocity = 0;

  @override
  CameraController? get cameraController => _controller;

  @override
  bool get isActive => _timer != null;

  @override
  Stream<TongueData> get stream => _stream.stream;

  @override
  Future<void> prepare() async {
    if (_controller?.value.isInitialized == true) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }

    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
  }

  @override
  Future<void> start() async {
    if (isActive) return;
    await prepare();

    _timer = Timer.periodic(
      const Duration(milliseconds: BioTrackingConstants.frameProcessingIntervalMs),
      (_) {
        _frame++;
        _stream.add(_simulateFromCamera());
      },
    );
  }

  TongueData _simulateFromCamera() {
    final time = _frame / BioTrackingConstants.framesPerSecond;
    final x = 0.5 +
        BioTrackingConstants.simulationAmplitudeX *
            sin(time * BioTrackingConstants.simulationFrequencyMultiplier);
    final y = 0.5 +
        BioTrackingConstants.simulationAmplitudeY *
            cos(time * BioTrackingConstants.simulationFrequencyMultiplier * 0.8);

    final position = Offset(x, y);
    final velocity =
        (position - _lastPosition).distance * BioTrackingConstants.framesPerSecond;
    final acceleration =
        (velocity - _lastVelocity) * BioTrackingConstants.framesPerSecond;

    _lastPosition = position;
    _lastVelocity = velocity;

    final landmarks = List<Offset>.generate(_cameraLandmarkCount, (i) {
      return Offset(
        x + (i - _cameraLandmarkCenterOffset) * _cameraLandmarkSpread,
        y + (i % _cameraLandmarkRowSize - 1) * _cameraLandmarkSpread,
      );
    });

    return TongueData(
      timestamp: DateTime.now(),
      position: position,
      velocity: velocity,
      acceleration: acceleration,
      landmarks: landmarks,
      isValidated: true,
    );
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
