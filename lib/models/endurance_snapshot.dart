import 'package:international_cunnibal/core/endurance_metrics.dart';

class EnduranceSnapshot {
  final double aperture;
  final double apertureStability;
  final double enduranceTime;
  final double enduranceScore;
  final double threshold;

  const EnduranceSnapshot({
    required this.aperture,
    required this.apertureStability,
    required this.enduranceTime,
    required this.enduranceScore,
    required this.threshold,
  });

  factory EnduranceSnapshot.empty({double threshold = 0.18}) {
    return EnduranceSnapshot(
      aperture: 0,
      apertureStability: 0,
      enduranceTime: 0,
      enduranceScore: 0,
      threshold: threshold,
    );
  }

  factory EnduranceSnapshot.fromResult(
    EnduranceMetricsResult result, {
    required double threshold,
  }) {
    return EnduranceSnapshot(
      aperture: result.aperture,
      apertureStability: result.apertureStability,
      enduranceTime: result.enduranceTime,
      enduranceScore: result.enduranceScore,
      threshold: threshold,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aperture': aperture,
      'apertureStability': apertureStability,
      'enduranceTime': enduranceTime,
      'enduranceScore': enduranceScore,
      'threshold': threshold,
    };
  }
}
