import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/utils/constants.dart';

enum CvEngineMode { demo, camera }

const double _demoJitterAmplitude = 0.01;
const int _faceMeshLandmarkCount = 309;
const double _cameraSecondaryFrequencyScale = 0.8;
const double _mouthWidth = 0.22;
const double _apertureBaseline = 0.22;
const double _apertureNoise = 0.04;
const double _apertureFatigueDrop = 0.06;
const double _apertureFatigueNoise = 0.06;

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
  final Random _random = Random(42);

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
      const Duration(
        milliseconds: BioTrackingConstants.frameProcessingIntervalMs,
      ),
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
    final aperture = _demoAperture(time, _random);

    final position = Offset(
      (0.5 + xWave + jitter).clamp(0.1, 0.9),
      (0.5 + yWave - jitter).clamp(0.1, 0.9),
    );

    final velocity =
        (position - _lastPosition).distance *
        BioTrackingConstants.framesPerSecond;
    final acceleration =
        (velocity - _lastVelocity) * BioTrackingConstants.framesPerSecond;

    _lastPosition = position;
    _lastVelocity = velocity;

    final landmarks = _buildFaceMeshLandmarks(
      center: position,
      aperture: aperture,
      noise: _demoJitterAmplitude,
      random: _random,
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
  final Random _random = Random(13);

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
      const Duration(
        milliseconds: BioTrackingConstants.frameProcessingIntervalMs,
      ),
      (_) {
        _frame++;
        _stream.add(_simulateFromCamera());
      },
    );
  }

  TongueData _simulateFromCamera() {
    final time = _frame / BioTrackingConstants.framesPerSecond;
    final x =
        0.5 +
        BioTrackingConstants.simulationAmplitudeX *
            sin(time * BioTrackingConstants.simulationFrequencyMultiplier);
    final y =
        0.5 +
        BioTrackingConstants.simulationAmplitudeY *
            cos(
              time *
                  BioTrackingConstants.simulationFrequencyMultiplier *
                  _cameraSecondaryFrequencyScale,
            );
    final aperture = _demoAperture(time, _random);

    final position = Offset(x, y);
    final velocity =
        (position - _lastPosition).distance *
        BioTrackingConstants.framesPerSecond;
    final acceleration =
        (velocity - _lastVelocity) * BioTrackingConstants.framesPerSecond;

    _lastPosition = position;
    _lastVelocity = velocity;

    final landmarks = _buildFaceMeshLandmarks(
      center: position,
      aperture: aperture,
      noise: 0.004,
      random: _random,
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

double _demoAperture(double tSeconds, Random random) {
  final cycle = tSeconds % 18.0;
  if (cycle < 6.0) {
    return _apertureBaseline + sin(tSeconds) * 0.01;
  }
  if (cycle < 12.0) {
    final noise = (random.nextDouble() - 0.5) * _apertureNoise;
    return (_apertureBaseline + noise).clamp(0.08, 0.5);
  }
  final fatigueProgress = ((cycle - 12.0) / 6.0).clamp(0.0, 1.0);
  final noise =
      (random.nextDouble() - 0.5) * (_apertureFatigueNoise * fatigueProgress);
  return (_apertureBaseline - _apertureFatigueDrop * fatigueProgress + noise)
      .clamp(0.06, 0.45);
}

List<Offset> _buildFaceMeshLandmarks({
  required Offset center,
  required double aperture,
  required double noise,
  required Random random,
}) {
  final landmarks = List<Offset>.filled(_faceMeshLandmarkCount, center);
  final left = Offset((center.dx - _mouthWidth).clamp(0.0, 1.0), center.dy);
  final right = Offset((center.dx + _mouthWidth).clamp(0.0, 1.0), center.dy);
  final halfAperture = (aperture * _mouthWidth).clamp(0.01, 0.2) / 2;
  final upper = Offset(center.dx, (center.dy - halfAperture).clamp(0.0, 1.0));
  final lower = Offset(center.dx, (center.dy + halfAperture).clamp(0.0, 1.0));

  landmarks[13] = upper;
  landmarks[14] = lower;
  landmarks[78] = left;
  landmarks[308] = right;

  for (var i = 0; i < 12; i++) {
    final idx = (i * 9) % _faceMeshLandmarkCount;
    final jitterX = (random.nextDouble() - 0.5) * noise;
    final jitterY = (random.nextDouble() - 0.5) * noise;
    landmarks[idx] = Offset(
      (center.dx + jitterX).clamp(0.0, 1.0),
      (center.dy + jitterY).clamp(0.0, 1.0),
    );
  }

  return landmarks;
}
