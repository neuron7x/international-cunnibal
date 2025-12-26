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

  final DateTime timestamp;

  const BiometricMetrics({
    required this.consistencyScore,
    required this.frequency,
    required this.pcaVariance,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'consistencyScore': consistencyScore,
      'frequency': frequency,
      'pcaVariance': pcaVariance,
    };
  }

  @override
  String toString() {
    return 'BiometricMetrics('
        'consistency: ${consistencyScore.toStringAsFixed(1)}%, '
        'frequency: ${frequency.toStringAsFixed(2)}Hz, '
        'PCA: [${pcaVariance.map((v) => v.toStringAsFixed(1)).join(", ")}]'
        ')';
  }
}
