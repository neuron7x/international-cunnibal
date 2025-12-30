import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/services/ml/mediapipe_service.dart';
import 'package:international_cunnibal/services/neural_engine.dart';
import 'package:international_cunnibal/services/ui/cv_engine.dart';
import 'package:international_cunnibal/utils/landmark_privacy.dart';

/// Status enum for tracking model loading state
enum TrackingStatus {
  /// Model not yet loaded
  notLoaded,
  /// Model loading in progress
  loading,
  /// Model loaded successfully - real tracking enabled
  loaded,
  /// Model loading failed - fallback to demo mode
  loadFailed,
  /// Demo mode active (no model needed)
  demo,
}

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
  final MediaPipeService _mediaPipeService = MediaPipeService();

  bool _isTracking = false;
  CvEngineMode _mode = CvEngineMode.demo;
  StreamSubscription? _engineSubscription;
  TrackingStatus _status = TrackingStatus.notLoaded;
  List<int> _labelIndices = [];

  bool get isTracking => _isTracking;
  bool get isDemoMode => _mode == CvEngineMode.demo;
  
  /// Returns true if real tracking is enabled (model loaded successfully)
  bool get isRealTrackingEnabled => 
      _status == TrackingStatus.loaded && _mode == CvEngineMode.camera;
  
  /// Returns current tracking status
  TrackingStatus get status => _status;
  
  /// Returns loaded label indices
  List<int> get labelIndices => List.unmodifiable(_labelIndices);
  
  CameraController? get cameraController =>
      _mode == CvEngineMode.camera ? _cameraEngine.cameraController : null;

  CvEngine get _engine =>
      _mode == CvEngineMode.demo ? _demoEngine : _cameraEngine;

  Future<void> setMode(CvEngineMode mode) async {
    if (_mode == mode) return;
    if (_isTracking) {
      stopTracking();
    }
    _mode = mode;
    if (_mode == CvEngineMode.demo) {
      _status = TrackingStatus.demo;
    }
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

  /// Load TFLite model for tongue detection with graceful fallback
  /// Reference: On-device AI for privacy (2025-11-30)
  Future<void> loadModel() async {
    if (_status == TrackingStatus.loading || _status == TrackingStatus.loaded) {
      return;
    }

    _status = TrackingStatus.loading;

    try {
      // Load labels first
      await _loadLabels();
      
      // Attempt to load TFLite model
      await _mediaPipeService.loadModel();
      
      _status = TrackingStatus.loaded;
    } catch (e) {
      // Graceful fallback to demo mode on failure
      _status = TrackingStatus.loadFailed;
      _mode = CvEngineMode.demo;
    }
  }

  /// Load label indices from assets
  Future<void> _loadLabels() async {
    try {
      final labelsContent = await rootBundle.loadString(
        'assets/models/labels.txt',
      );
      _labelIndices = labelsContent
          .split('\n')
          .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
          .map((line) => int.tryParse(line.trim()))
          .whereType<int>()
          .toList();
    } on Exception catch (e) {
      _labelIndices = [];
      // Log error for debugging but allow graceful fallback
      debugPrint('Failed to load labels.txt: $e');
      rethrow;
    }
  }

  Future<void> prepare() async {
    await _engine.prepare();
  }

  void dispose() {
    stopTracking();
    _cameraEngine.cameraController?.dispose();
    _mediaPipeService.dispose();
  }

  void _onSample(TongueData data) {
    final filtered = data.copyWith(
      landmarks: LandmarkPrivacyFilter.stripFaceLandmarks(data.landmarks),
    );
    _neuralEngine.processTongueData(filtered);
  }
}
