import 'dart:async';
import 'package:camera/camera.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/services/neural_engine.dart';
import 'package:international_cunnibal/services/ui/cv_engine.dart';
import 'package:international_cunnibal/utils/landmark_privacy.dart';

/// Bio-Tracking service for real-time tongue biomechanics
/// Uses MediaPipe/TFLite for on-device AI processing
/// 
/// Reference: Real-time tongue biomechanics tracking (2025-11-30)
class BioTrackingService {
  static final BioTrackingService _instance = BioTrackingService._internal();
  factory BioTrackingService() => _instance;
  BioTrackingService._internal();

  final NeuralEngine _neuralEngine = NeuralEngine();
  final CvEngine _demoEngine = DemoCvEngine();
  final CvEngine _cameraEngine = CameraCvEngine();
  
  bool _isTracking = false;
  CvEngineMode _mode = CvEngineMode.demo;
  StreamSubscription? _engineSubscription;

  bool get isTracking => _isTracking;
  bool get isDemoMode => _mode == CvEngineMode.demo;
  CameraController? get cameraController =>
      _mode == CvEngineMode.camera ? _cameraEngine.cameraController : null;

  CvEngine get _engine => _mode == CvEngineMode.demo ? _demoEngine : _cameraEngine;

  Future<void> setMode(CvEngineMode mode) async {
    if (_mode == mode) return;
    if (_isTracking) {
      stopTracking();
    }
    _mode = mode;
  }

  /// Start real-time bio-tracking
  Future<void> startTracking() async {
    if (_isTracking) return;

    await prepare();

    _isTracking = true;
    _neuralEngine.start();

    _engineSubscription = _engine.stream.listen(_onSample);
    await _engine.start();
  }

  /// Stop bio-tracking
  void stopTracking() {
    _isTracking = false;
    _engineSubscription?.cancel();
    _engineSubscription = null;
    _engine.stop();
    _neuralEngine.stop();
  }

  /// Load TFLite model for tongue detection
  /// Reference: On-device AI for privacy (2025-11-30)
  Future<void> loadModel() async {
    // In production, load TFLite model:
    // await Tflite.loadModel(
    //   model: 'assets/models/tongue_detector.tflite',
    //   labels: 'assets/models/labels.txt',
    // );
  }

  Future<void> prepare() async {
    await _engine.prepare();
  }

  void dispose() {
    stopTracking();
    _cameraEngine.cameraController?.dispose();
  }

  void _onSample(TongueData data) {
    final filtered = data.copyWith(
      landmarks: LandmarkPrivacyFilter.stripFaceLandmarks(data.landmarks),
    );
    _neuralEngine.processTongueData(filtered);
  }
}
