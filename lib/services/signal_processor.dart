import 'dart:math';
import 'package:flutter/material.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/utils/constants.dart';

const int _directionSampleWindowSize = 6;
const double _steadyMovementThreshold = 0.02;
const double _directionStabilityScale = 120;

class SignalProcessor {
  BiometricMetrics calculate(List<TongueData> buffer) {
    if (buffer.isEmpty) {
      return BiometricMetrics.empty();
    }

    final velocities = buffer.map((d) => d.velocity).toList();
    final consistencyScore = _calculateConsistencyScore(velocities);
    final frequency = _calculateFrequency(buffer);
    final pcaVariance = _calculatePCA(buffer);
    final direction = _calculateDirection(buffer);

    return BiometricMetrics(
      consistencyScore: consistencyScore,
      frequency: frequency,
      pcaVariance: pcaVariance,
      movementDirection: direction.$1,
      directionStability: direction.$2,
      timestamp: DateTime.now(),
    );
  }

  double _calculateConsistencyScore(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = sqrt(variance);

    return (100 - (stdDev * NeuralEngineConstants.stdDevScalingFactor))
        .clamp(0.0, 100.0);
  }

  double _calculateFrequency(List<TongueData> buffer) {
    if (buffer.length < 3) return 0.0;

    int peaks = 0;
    for (int i = 1; i < buffer.length - 1; i++) {
      if (buffer[i].velocity > buffer[i - 1].velocity &&
          buffer[i].velocity > buffer[i + 1].velocity) {
        peaks++;
      }
    }

    final timeSpan = buffer.last.timestamp
            .difference(buffer.first.timestamp)
            .inMilliseconds /
        1000.0;

    return timeSpan > 0 ? peaks / timeSpan : 0.0;
  }

  List<double> _calculatePCA(List<TongueData> buffer) {
    if (buffer.length < 3) return [0.0, 0.0, 0.0];

    final xValues = buffer.map((d) => d.position.dx).toList();
    final yValues = buffer.map((d) => d.position.dy).toList();

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

  (MovementDirection, double) _calculateDirection(List<TongueData> buffer) {
    final sampleCount = buffer.length;
    if (sampleCount < 2) return (MovementDirection.steady, 0.0);

    final startIndex = sampleCount - _directionSampleWindowSize;
    final safeStartIndex = startIndex < 0 ? 0 : startIndex;
    final start = buffer[safeStartIndex].position;
    final end = buffer.last.position;
    final delta = end - start;

    if (delta.distance < _steadyMovementThreshold) {
      return (MovementDirection.steady, 0.0);
    }

    MovementDirection direction;
    if (delta.dx.abs() > delta.dy.abs()) {
      direction = delta.dx > 0 ? MovementDirection.right : MovementDirection.left;
    } else {
      direction = delta.dy > 0 ? MovementDirection.down : MovementDirection.up;
    }

    final stability = (delta.distance * _directionStabilityScale).clamp(0.0, 100.0);
    return (direction, stability);
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    return values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
  }
}
