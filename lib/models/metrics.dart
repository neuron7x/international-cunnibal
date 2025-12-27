import 'package:international_cunnibal/models/movement_direction.dart';

/// Biometric metrics calculated from tongue biomechanics
/// Reference: Metrics calculation (2025-11-30)
class BiometricMetrics {
  /// Consistency Score based on Standard Deviation (0-100)
  /// Higher score = more consistent movement patterns
  final double consistencyScore;

  /// Movement frequency in Hz
  final double frequency;

  /// PCA variance explained by principal components [PC1, PC2, PC3]
  /// Represents dimensional reduction of movement patterns
  final List<double> pcaVariance;

  /// Dominant movement direction for recent window
  final MovementDirection movementDirection;

  /// Stability of the dominant direction (0-100)
  final double directionStability;

  final DateTime timestamp;

  const BiometricMetrics({
    required this.consistencyScore,
    required this.frequency,
    required this.pcaVariance,
    required this.movementDirection,
    required this.directionStability,
    required this.timestamp,
  });

  factory BiometricMetrics.empty() {
    return BiometricMetrics(
      consistencyScore: 0,
      frequency: 0,
      pcaVariance: const [0, 0, 0],
      movementDirection: MovementDirection.steady,
      directionStability: 0,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'consistencyScore': consistencyScore,
      'frequency': frequency,
      'pcaVariance': pcaVariance,
      'movementDirection': movementDirection.label,
      'directionStability': directionStability,
    };
  }

  @override
  String toString() {
    return 'BiometricMetrics('
        'consistency: ${consistencyScore.toStringAsFixed(1)}%, '
        'frequency: ${frequency.toStringAsFixed(2)}Hz, '
        'direction: ${movementDirection.label} '
        '(${directionStability.toStringAsFixed(1)}), '
        'PCA: [${pcaVariance.map((v) => v.toStringAsFixed(1)).join(", ")}]'
        ')';
  }
}
