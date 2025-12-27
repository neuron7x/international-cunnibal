import 'dart:async';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/services/game_logic_service.dart';
import 'package:international_cunnibal/services/signal_processor.dart';
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

  final StreamController<TongueData> _tongueDataController =
      StreamController<TongueData>.broadcast();
  final StreamController<BiometricMetrics> _metricsController =
      StreamController<BiometricMetrics>.broadcast();

  Stream<TongueData> get tongueDataStream => _tongueDataController.stream;
  Stream<BiometricMetrics> get metricsStream => _metricsController.stream;

  final List<TongueData> _dataBuffer = [];
  final int _bufferSize = NeuralEngineConstants.bufferSize;
  final SignalProcessor _signalProcessor = SignalProcessor();
  final GameLogicService _gameLogic = GameLogicService();
  
  bool _isProcessing = false;
  Timer? _metricsTimer;

  /// Start the neural engine processing
  void start() {
    if (_isProcessing) return;
    
    _isProcessing = true;
    _dataBuffer.clear();
    
    // Calculate metrics every second
    _metricsTimer = Timer.periodic(
      Duration(seconds: NeuralEngineConstants.metricsUpdateIntervalSeconds),
      (_) {
        if (_dataBuffer.isNotEmpty) {
          final metrics = _calculateMetrics();
          _metricsController.add(metrics);
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
  }

  /// Process incoming tongue biomechanics data
  /// Implements the Action Acceptor pattern for sensory-motor validation
  void processTongueData(TongueData data) {
    if (!_isProcessing) return;

    // Add to buffer, maintaining buffer size
    _dataBuffer.add(data);
    if (_dataBuffer.length > _bufferSize) {
      _dataBuffer.removeAt(0);
    }

    // Apply Action Acceptor pattern:
    // 1. Accept afferent (sensory) input
    // 2. Compare with expected pattern
    // 3. Validate motor command execution
    final validated = _validateAction(data);
    
    _tongueDataController.add(validated);
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

    return _signalProcessor.calculate(_dataBuffer);
  }

  void dispose() {
    stop();
  }
}
