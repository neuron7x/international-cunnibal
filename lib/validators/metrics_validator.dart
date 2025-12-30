import 'package:flutter/foundation.dart';
import 'package:international_cunnibal/models/metrics.dart';

class ValidationError {
  final String field;
  final dynamic value;
  final String constraint;

  ValidationError(this.field, this.value, this.constraint);

  @override
  String toString() =>
      'Field "$field" = $value violates constraint: $constraint';
}

class MetricsValidator {
  static List<ValidationError> validate(BiometricMetrics m) {
    final errors = <ValidationError>[];

    if (m.consistencyScore < 0 || m.consistencyScore > 100) {
      errors.add(
        ValidationError('consistencyScore', m.consistencyScore, '0 <= x <= 100'),
      );
    }

    if (m.frequency <= 0) {
      errors.add(
        ValidationError('frequency', m.frequency, 'x > 0'),
      );
    }

    if (m.frequencyConfidence < 0 || m.frequencyConfidence > 1) {
      errors.add(
        ValidationError('frequencyConfidence', m.frequencyConfidence, '0 <= x <= 1'),
      );
    }

    if (m.pcaVariance.isNotEmpty) {
      final pcaSum = m.pcaVariance.reduce((a, b) => a + b);
      if ((pcaSum - 1.0).abs() > 0.05) {
        errors.add(
          ValidationError('pcaVariance', m.pcaVariance, 'sum should ≈ 1.0'),
        );
      }

      for (final v in m.pcaVariance) {
        if (v < 0 || v > 1) {
          errors.add(
            ValidationError('pcaVariance', v, 'each component 0 <= x <= 1'),
          );
        }
      }
    }

    if (m.endurance.enduranceScore < 0 || m.endurance.enduranceScore > 100) {
      errors.add(
        ValidationError('enduranceScore', m.endurance.enduranceScore, '0 <= x <= 100'),
      );
    }

    final now = DateTime.now();
    final minValid = DateTime(2025, 1, 1);
    if (m.timestamp.isBefore(minValid) || m.timestamp.isAfter(now)) {
      errors.add(
        ValidationError(
          'timestamp',
          m.timestamp,
          '$minValid <= x <= $now',
        ),
      );
    }

    if (errors.isNotEmpty && kDebugMode) {
      debugPrint('Invalid metrics detected: $errors');
    }

    return errors;
  }
}
