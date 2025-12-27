import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/models/movement_direction.dart';

/// Biometric metrics calculated from tongue biomechanics
/// Reference: Metrics calculation (2025-11-30)
class BiometricMetrics {
  /// Consistency Score based on Standard Deviation (0-100)
  /// Higher score = more consistent movement patterns
  final double consistencyScore;

  /// Movement frequency in Hz
  final double frequency;
  /// Frequency confidence (0-1)
  final double frequencyConfidence;

  /// PCA variance explained by principal components [PC1, PC2, PC3]
  /// Represents dimensional reduction of movement patterns
  final List<double> pcaVariance;

  /// Dominant movement direction for recent window
  final MovementDirection movementDirection;

  /// Stability of the dominant direction (0-100)
  final double directionStability;

  /// Intensity proxy (0-100)
  final double intensity;

  /// Optional pattern match score (0-100)
  final double patternScore;

  /// Jaw endurance snapshot (aperture control)
  final EnduranceSnapshot endurance;

  final DateTime timestamp;

  const BiometricMetrics({
    required this.consistencyScore,
    required this.frequency,
    required this.frequencyConfidence,
    required this.pcaVariance,
    required this.movementDirection,
    required this.directionStability,
    required this.intensity,
    required this.patternScore,
    required this.endurance,
    required this.timestamp,
  });

  factory BiometricMetrics.empty() {
    return BiometricMetrics(
      consistencyScore: 0,
      frequency: 0,
      frequencyConfidence: 0,
      pcaVariance: const [0, 0, 0],
      movementDirection: MovementDirection.steady,
      directionStability: 0,
      intensity: 0,
      patternScore: 0,
      endurance: EnduranceSnapshot.empty(),
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'consistencyScore': consistencyScore,
      'frequency': frequency,
      'frequencyConfidence': frequencyConfidence,
      'pcaVariance': pcaVariance,
      'movementDirection': movementDirection.label,
      'directionStability': directionStability,
      'intensity': intensity,
      'patternScore': patternScore,
      'endurance': endurance.toJson(),
    };
  }

  @override
  String toString() {
    return 'BiometricMetrics('
        'consistency: ${consistencyScore.toStringAsFixed(1)}%, '
        'frequency: ${frequency.toStringAsFixed(2)}Hz@${(frequencyConfidence * 100).toStringAsFixed(0)}%, '
        'direction: ${movementDirection.label} (${directionStability.toStringAsFixed(1)}), '
        'intensity: ${intensity.toStringAsFixed(1)}, '
        'pattern: ${patternScore.toStringAsFixed(1)}, '
        'endurance: ${endurance.enduranceScore.toStringAsFixed(1)} '
        '(aperture ${endurance.aperture.toStringAsFixed(3)}), '
        'PCA: [${pcaVariance.map((v) => v.toStringAsFixed(1)).join(", ")}]'
        ')';
  }
}
