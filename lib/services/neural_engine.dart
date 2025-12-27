import 'dart:async';
import 'package:international_cunnibal/core/motion_metrics.dart';
import 'package:international_cunnibal/services/endurance_engine.dart';
import 'package:international_cunnibal/services/endurance_game_logic_service.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/services/game_logic_service.dart';
import 'package:international_cunnibal/utils/constants.dart';

/// NeuralEngine service implementing Anokhin's Action Acceptor
/// 
/// Based on Anokhin's theory of functional systems and action acceptor,
/// this engine processes tongue biomechanics and validates motor patterns
/// against expected outcomes for sensory-motor synchronization.
/// 
/// Reference: Anokhin's Action Acceptor theory (2025-11-30)
class NeuralEngine {
  static final NeuralEngine _instance = NeuralEngine._internal();
  factory NeuralEngine() => _instance;
  NeuralEngine._internal();

  StreamController<TongueData>? _tongueDataController;
  StreamController<BiometricMetrics>? _metricsController;
  bool _enduranceEnabled = false;

  Stream<TongueData> get tongueDataStream {
    _ensureControllers();
    return _tongueDataController!.stream;
  }

  Stream<BiometricMetrics> get metricsStream {
    _ensureControllers();
    return _metricsController!.stream;
  }

  final List<TongueData> _dataBuffer = [];
  final int _bufferSize = NeuralEngineConstants.bufferSize;
  final GameLogicService _gameLogic = GameLogicService();
  final EnduranceEngine _enduranceEngine = EnduranceEngine();
  final EnduranceGameLogicService _enduranceGameLogic = EnduranceGameLogicService();

  void _resetControllers() {
    _tongueDataController?.close();
    _metricsController?.close();
    _tongueDataController = StreamController<TongueData>.broadcast();
    _metricsController = StreamController<BiometricMetrics>.broadcast();
  }

  void _ensureControllers() {
    if (_tongueDataController == null ||
        _metricsController == null ||
        _tongueDataController!.isClosed ||
        _metricsController!.isClosed) {
      _resetControllers();
    }
  }
  
  bool _isProcessing = false;
  Timer? _metricsTimer;

  /// Start the neural engine processing
  void start() {
    if (_isProcessing) return;
    _ensureControllers();
    final metricsController = _metricsController;
    if (metricsController == null) return;
    
    _isProcessing = true;
    _dataBuffer.clear();
    _enduranceEngine.reset();
    
    // Calculate metrics every second
    _metricsTimer = Timer.periodic(
      Duration(seconds: NeuralEngineConstants.metricsUpdateIntervalSeconds),
      (_) {
        if (_dataBuffer.isNotEmpty) {
          final metrics = _calculateMetrics();
          metricsController.add(metrics);
          _gameLogic.ingest(metrics);
        }
      },
    );
  }

  /// Stop the neural engine processing
  void stop() {
    _isProcessing = false;
    _metricsTimer?.cancel();
    _metricsTimer = null;
    _enduranceEngine.reset();
  }

  void configureEndurance({required bool enabled}) {
    _enduranceEnabled = enabled;
    if (!enabled) {
      _enduranceEngine.reset();
    }
  }

  /// Process incoming tongue biomechanics data
  /// Implements the Action Acceptor pattern for sensory-motor validation
  void processTongueData(TongueData data) {
    if (!_isProcessing) return;
    _ensureControllers();
    final tongueController = _tongueDataController;
    if (tongueController == null) return;

    // Add to buffer, maintaining buffer size
    _dataBuffer.add(data);
    if (_dataBuffer.length > _bufferSize) {
      _dataBuffer.removeAt(0);
    }
    _ingestEndurance(data);

    // Apply Action Acceptor pattern:
    // 1. Accept afferent (sensory) input
    // 2. Compare with expected pattern
    // 3. Validate motor command execution
    final validated = _validateAction(data);
    
    tongueController.add(validated);
  }

  /// Validate action using Anokhin's Action Acceptor principle
  TongueData _validateAction(TongueData data) {
    // Action Acceptor compares actual afferent signals with expected ones
    // Here we validate the biomechanics consistency
    
    if (_dataBuffer.length < 2) return data;
    
    final previous = _dataBuffer[_dataBuffer.length - 2];
    final velocityChange = (data.velocity - previous.velocity).abs();
    final isConsistent = velocityChange < NeuralEngineConstants.velocityChangeThreshold;
    
    return TongueData(
      timestamp: data.timestamp,
      position: data.position,
      velocity: data.velocity,
      acceleration: data.acceleration,
      landmarks: data.landmarks,
      isValidated: isConsistent,
    );
  }

  /// Calculate biometric metrics
  BiometricMetrics _calculateMetrics() {
    if (_dataBuffer.isEmpty) {
      return BiometricMetrics.empty();
    }

    final samples = _dataBuffer
        .map((d) => MotionSample(
              t: d.timestamp.millisecondsSinceEpoch / 1000.0,
              position: Vector2(d.position.dx, d.position.dy),
            ))
        .toList();

    final motion = MotionMetrics.compute(
      samples: samples,
      expectedAmplitude: NeuralEngineConstants.expectedAmplitude,
    );
    final endurance = _enduranceEnabled
        ? _enduranceEngine.snapshot()
        : EnduranceSnapshot.empty(
            threshold: EnduranceConstants.defaultApertureThreshold,
          );
    if (_enduranceEnabled) {
      _enduranceGameLogic.ingest(endurance);
    }

    final pca = _calculatePCA();

    return BiometricMetrics(
      consistencyScore: motion.consistency,
      frequency: motion.frequency.hertz,
      frequencyConfidence: motion.frequency.confidence,
      pcaVariance: pca,
      movementDirection: _toDirection(motion.direction.direction),
      directionStability: motion.direction.stability,
      intensity: motion.intensity,
      patternScore: motion.patternMatch.score,
      endurance: endurance,
      timestamp: DateTime.now(),
    );
  }

  MovementDirection _toDirection(Vector2 v) {
    if (v.magnitude < 1e-6) return MovementDirection.steady;
    if (v.x.abs() >= v.y.abs()) {
      return v.x >= 0 ? MovementDirection.right : MovementDirection.left;
    }
    return v.y >= 0 ? MovementDirection.down : MovementDirection.up;
  }

  /// Calculate PCA variance for dimensional reduction
  /// Simplified PCA for 3 principal components
  List<double> _calculatePCA() {
    if (_dataBuffer.length < 3) return [0.0, 0.0, 0.0];
    
    final positions = _dataBuffer
        .map((d) => d.position)
        .toList();
    
    final xValues = positions.map((p) => p.dx).toList();
    final yValues = positions.map((p) => p.dy).toList();
    
    final xVariance = _calculateVariance(xValues);
    final yVariance = _calculateVariance(yValues);
    final totalVariance = xVariance + yVariance;
    
    if (totalVariance == 0) return [0.0, 0.0, 0.0];
    
    return [
      (xVariance / totalVariance) * 100,
      (yVariance / totalVariance) * 100,
      0.0,
    ];
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    return values
        .map((v) => (v - mean) * (v - mean))
        .reduce((a, b) => a + b) / values.length;
  }

  void _ingestEndurance(TongueData data) {
    if (!_enduranceEnabled) return;
    final landmarks = data.landmarks
        .map((o) => Vector2(o.dx, o.dy))
        .toList();
    final tSeconds = data.timestamp.millisecondsSinceEpoch / 1000.0;
    _enduranceEngine.ingestLandmarks(
      tSeconds: tSeconds,
      landmarks: landmarks,
    );
  }

  void dispose() {
    stop();
    _tongueDataController?.close();
    _metricsController?.close();
    _tongueDataController = null;
    _metricsController = null;
  }
}
