import 'dart:math';

import 'package:international_cunnibal/core/endurance_metrics.dart';
import 'package:international_cunnibal/core/motion_metrics.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/utils/constants.dart';

class EnduranceEngine {
  final int bufferSize;
  final double apertureThreshold;

  final List<ApertureSample> _buffer = [];

  EnduranceEngine({this.bufferSize = 180, double? apertureThreshold})
    : apertureThreshold =
          apertureThreshold ?? EnduranceConstants.defaultApertureThreshold;

  EnduranceSnapshot ingestLandmarks({
    required double tSeconds,
    required List<Vector2> landmarks,
  }) {
    final sample = _sampleFromLandmarks(tSeconds, landmarks);
    return ingestSample(sample);
  }

  EnduranceSnapshot ingestSample(ApertureSample? sample) {
    if (sample != null) {
      _buffer.add(sample);
      if (_buffer.length > bufferSize) {
        _buffer.removeAt(0);
      }
    }
    if (_buffer.length < 2) {
      return EnduranceSnapshot.empty(threshold: apertureThreshold);
    }
    final result = EnduranceMetrics.compute(
      samples: _buffer,
      apertureThreshold: apertureThreshold,
      apertureMin: EnduranceConstants.apertureMin,
      apertureMax: EnduranceConstants.apertureMax,
    );
    return EnduranceSnapshot.fromResult(result, threshold: apertureThreshold);
  }

  EnduranceSnapshot demoTick(double tSeconds) {
    final cycle = tSeconds % 18.0;
    double base;
    if (cycle < 6.0) {
      base = 0.22 + 0.015 * sin(tSeconds);
    } else if (cycle < 12.0) {
      base = 0.22 + 0.02 * sin(tSeconds * 4.0);
    } else {
      final fatigue = ((cycle - 12.0) / 6.0).clamp(0.0, 1.0);
      base = 0.22 - 0.05 * fatigue + 0.01 * sin(tSeconds * 6.0);
    }
    final sample = ApertureSample(
      t: tSeconds,
      upperLip: Vector2(0.5, 0.5 - base),
      lowerLip: Vector2(0.5, 0.5 + base),
      leftCorner: const Vector2(0.4, 0.5),
      rightCorner: const Vector2(0.6, 0.5),
    );
    return ingestSample(sample);
  }

  void reset() {
    _buffer.clear();
  }

  ApertureSample? _sampleFromLandmarks(
    double tSeconds,
    List<Vector2> landmarks,
  ) {
    if (landmarks.length >= 309) {
      return ApertureSample(
        t: tSeconds,
        upperLip: landmarks[13],
        lowerLip: landmarks[14],
        leftCorner: landmarks[78],
        rightCorner: landmarks[308],
      );
    }

    if (landmarks.isEmpty) return null;
    final anchor = landmarks.first;
    final offset = 0.02;
    return ApertureSample(
      t: tSeconds,
      upperLip: _bounded(anchor.x, anchor.y - offset),
      lowerLip: _bounded(anchor.x, anchor.y + offset),
      leftCorner: _bounded(anchor.x - offset, anchor.y),
      rightCorner: _bounded(anchor.x + offset, anchor.y),
    );
  }

  Vector2 _bounded(double x, double y) {
    return Vector2(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
  }

  EnduranceSnapshot snapshot() {
    if (_buffer.length < 2) {
      return EnduranceSnapshot.empty(threshold: apertureThreshold);
    }
    final result = EnduranceMetrics.compute(
      samples: _buffer,
      apertureThreshold: apertureThreshold,
      apertureMin: EnduranceConstants.apertureMin,
      apertureMax: EnduranceConstants.apertureMax,
    );
    return EnduranceSnapshot.fromResult(result, threshold: apertureThreshold);
  }
}
