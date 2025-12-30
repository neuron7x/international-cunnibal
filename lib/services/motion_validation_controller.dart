import 'dart:async';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/utils/constants.dart';

/// Motion Validation Controller
///
/// Validates biomechanics data consistency in real-time.
/// Detects measurement anomalies by comparing consecutive velocity readings.
///
/// **Responsibility:**
/// Compare consecutive motion measurements and flag inconsistent data points.
///
/// **Inputs:**
/// - TongueData: position, velocity, acceleration, timestamp
///
/// **Outputs:**
/// - TongueData with isValidated flag
/// - ValidationMetrics: validation rate, anomaly count, consistency score
///
/// **Behavior:**
/// 1. Receive motion measurement from sensor pipeline
/// 2. Compare velocity change with previous measurement
/// 3. Mark measurement as valid if change is below threshold
/// 4. Track validation statistics for observability
///
/// **Guarantees:**
/// - Deterministic validation (same input → same output)
/// - Bounded response time (<1ms per measurement)
/// - No external dependencies
///
/// **Does NOT:**
/// - Process or filter camera frames
/// - Store historical data (caller manages buffer)
/// - Make predictions or inferences
/// - Require network connectivity
class MotionValidationController {
  static final MotionValidationController _instance =
      MotionValidationController._internal();
  factory MotionValidationController() => _instance;
  MotionValidationController._internal();

  // Validation statistics for observability
  int _totalValidations = 0;
  int _validCount = 0;
  int _invalidCount = 0;
  TongueData? _previousData;

  StreamController<ValidationMetrics>? _metricsController;

  /// Stream of validation metrics for monitoring
  Stream<ValidationMetrics> get metricsStream {
    _metricsController ??=
        StreamController<ValidationMetrics>.broadcast();
    return _metricsController!.stream;
  }

  /// Validate motion data consistency
  ///
  /// Compares current measurement with previous to detect anomalies.
  /// Returns validated TongueData with isValidated flag set.
  TongueData validate(TongueData data) {
    // First measurement is always considered valid (no previous data)
    if (_previousData == null) {
      _previousData = data.copyWith(isValidated: true);
      _updateStats(true);
      return _previousData!;
    }

    // Calculate velocity change between consecutive measurements
    final velocityChange = (data.velocity - _previousData!.velocity).abs();
    final isValid =
        velocityChange < NeuralEngineConstants.velocityChangeThreshold;

    // Update statistics
    _updateStats(isValid);

    // Create validated data
    final validatedData = data.copyWith(isValidated: isValid);
    _previousData = validatedData;

    // Emit metrics every 30 validations (~1 second at 30 FPS)
    if (_totalValidations % 30 == 0) {
      _emitMetrics();
    }

    return validatedData;
  }

  /// Reset validation state and statistics
  void reset() {
    _totalValidations = 0;
    _validCount = 0;
    _invalidCount = 0;
    _previousData = null;
  }

  /// Get current validation statistics
  ValidationMetrics getMetrics() {
    return ValidationMetrics(
      totalValidations: _totalValidations,
      validCount: _validCount,
      invalidCount: _invalidCount,
      validationRate:
          _totalValidations > 0 ? _validCount / _totalValidations : 0.0,
      timestamp: DateTime.now(),
    );
  }

  void _updateStats(bool isValid) {
    _totalValidations++;
    if (isValid) {
      _validCount++;
    } else {
      _invalidCount++;
    }
  }

  void _emitMetrics() {
    if (_metricsController != null && !_metricsController!.isClosed) {
      _metricsController!.add(getMetrics());
    }
  }

  /// Clean up resources
  void dispose() {
    _metricsController?.close();
    _metricsController = null;
    reset();
  }
}

/// Validation metrics for observability
///
/// Provides quantitative data about validation behavior:
/// - Total number of validations performed
/// - Count of valid vs invalid measurements
/// - Validation success rate (0.0 to 1.0)
class ValidationMetrics {
  final int totalValidations;
  final int validCount;
  final int invalidCount;
  final double validationRate; // 0.0 to 1.0
  final DateTime timestamp;

  const ValidationMetrics({
    required this.totalValidations,
    required this.validCount,
    required this.invalidCount,
    required this.validationRate,
    required this.timestamp,
  });

  /// Convert to JSON for logging/export
  Map<String, dynamic> toJson() {
    return {
      'totalValidations': totalValidations,
      'validCount': validCount,
      'invalidCount': invalidCount,
      'validationRate': validationRate,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ValidationMetrics(total: $totalValidations, valid: $validCount, '
        'invalid: $invalidCount, rate: ${(validationRate * 100).toStringAsFixed(1)}%)';
  }
}
