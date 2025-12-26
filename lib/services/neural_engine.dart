import 'dart:async';
import 'dart:math';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/models/metrics.dart';

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
  final int _bufferSize = 100; // Store last 100 samples for analysis
  
  bool _isProcessing = false;
  Timer? _metricsTimer;

  /// Start the neural engine processing
  void start() {
    if (_isProcessing) return;
    
    _isProcessing = true;
    _dataBuffer.clear();
    
    // Calculate metrics every second
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_dataBuffer.isNotEmpty) {
        final metrics = _calculateMetrics();
        _metricsController.add(metrics);
      }
    });
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
    final isConsistent = velocityChange < 0.5; // Threshold for consistency
    
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
      return BiometricMetrics(
        consistencyScore: 0.0,
        frequency: 0.0,
        pcaVariance: [0.0, 0.0, 0.0],
        timestamp: DateTime.now(),
      );
    }

    // Consistency Score (Standard Deviation)
    final velocities = _dataBuffer.map((d) => d.velocity).toList();
    final consistencyScore = _calculateConsistencyScore(velocities);

    // Frequency (Hz) - movements per second
    final frequency = _calculateFrequency();

    // Vector PCA for dimensional reduction
    final pcaVariance = _calculatePCA();

    return BiometricMetrics(
      consistencyScore: consistencyScore,
      frequency: frequency,
      pcaVariance: pcaVariance,
      timestamp: DateTime.now(),
    );
  }

  /// Calculate consistency score using standard deviation
  /// Lower std dev = higher consistency
  double _calculateConsistencyScore(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((v) => pow(v - mean, 2))
        .reduce((a, b) => a + b) / values.length;
    final stdDev = sqrt(variance);
    
    // Normalize to 0-100 scale (inverse, so lower stdDev = higher score)
    return max(0, 100 - (stdDev * 50)).clamp(0.0, 100.0);
  }

  /// Calculate movement frequency in Hz
  double _calculateFrequency() {
    if (_dataBuffer.length < 2) return 0.0;
    
    // Count peaks in velocity data
    int peaks = 0;
    for (int i = 1; i < _dataBuffer.length - 1; i++) {
      if (_dataBuffer[i].velocity > _dataBuffer[i - 1].velocity &&
          _dataBuffer[i].velocity > _dataBuffer[i + 1].velocity) {
        peaks++;
      }
    }
    
    // Calculate time span
    final timeSpan = _dataBuffer.last.timestamp
        .difference(_dataBuffer.first.timestamp)
        .inMilliseconds / 1000.0;
    
    return timeSpan > 0 ? peaks / timeSpan : 0.0;
  }

  /// Calculate PCA variance for dimensional reduction
  /// Simplified PCA for 3 principal components
  List<double> _calculatePCA() {
    if (_dataBuffer.length < 3) return [0.0, 0.0, 0.0];
    
    // Extract position vectors
    final positions = _dataBuffer
        .map((d) => d.position)
        .toList();
    
    // Calculate variance along each axis (simplified PCA)
    final xValues = positions.map((p) => p.dx).toList();
    final yValues = positions.map((p) => p.dy).toList();
    
    final xVariance = _calculateVariance(xValues);
    final yVariance = _calculateVariance(yValues);
    final totalVariance = xVariance + yVariance;
    
    if (totalVariance == 0) return [0.0, 0.0, 0.0];
    
    // Return explained variance ratios
    return [
      (xVariance / totalVariance) * 100,
      (yVariance / totalVariance) * 100,
      0.0, // Third component (could be expanded for 3D tracking)
    ];
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    return values
        .map((v) => pow(v - mean, 2))
        .reduce((a, b) => a + b) / values.length;
  }

  void dispose() {
    stop();
    _tongueDataController.close();
    _metricsController.close();
  }
}
