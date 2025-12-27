import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/models/endurance_state.dart';
import 'package:international_cunnibal/models/game_state.dart';
import 'package:international_cunnibal/models/metrics.dart';

class CoupleComparisonRow {
  final String leftLabel;
  final double leftValue;
  final String rightLabel;
  final double rightValue;

  const CoupleComparisonRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });
}

class CoupleDashboard {
  final CoupleComparisonRow consistencyVsEndurance;
  final CoupleComparisonRow directionVsStability;
  final CoupleComparisonRow levelVsLevel;
  final bool comparisonsEnabled;

  const CoupleDashboard({
    required this.consistencyVsEndurance,
    required this.directionVsStability,
    required this.levelVsLevel,
    required this.comparisonsEnabled,
  });

  factory CoupleDashboard.fromInputs({
    required BiometricMetrics motion,
    required GameState motionState,
    required EnduranceSnapshot endurance,
    EnduranceState? enduranceState,
    bool comparisonsEnabled = false,
  }) {
    final enduranceLevel = enduranceState?.level ?? 1;
    return CoupleDashboard(
      comparisonsEnabled: comparisonsEnabled,
      consistencyVsEndurance: CoupleComparisonRow(
        leftLabel: 'Consistency',
        leftValue: motion.consistencyScore,
        rightLabel: 'Endurance',
        rightValue: endurance.enduranceScore,
      ),
      directionVsStability: CoupleComparisonRow(
        leftLabel: 'Vector Stability',
        leftValue: motion.directionStability,
        rightLabel: 'Aperture Stability',
        rightValue: endurance.apertureStability,
      ),
      levelVsLevel: CoupleComparisonRow(
        leftLabel: 'Motion Level',
        leftValue: motionState.level.toDouble(),
        rightLabel: 'Endurance Level',
        rightValue: enduranceLevel.toDouble(),
      ),
    );
  }
}
