import 'dart:math';
import 'package:international_cunnibal/core/motion_metrics.dart';

/// Benchmark script for motion metrics and model inference timing
/// Usage: dart run tool/benchmark_core.dart
Future<void> main() async {
  print('=== International Cunnibal Benchmarks ===\n');
  
  // Benchmark 1: Motion Metrics Core
  await _benchmarkMotionMetrics();
  
  // Benchmark 2: Model Inference (placeholder)
  await _benchmarkModelInference();
}

Future<void> _benchmarkMotionMetrics() async {
  print('Benchmark 1: Motion Metrics (30 FPS window processing)');
  print('---');
  
  final samples = List.generate(240, (i) {
    final t = i * 0.016;
    return MotionSample(
      t: t,
      position: Vector2(
        0.5 + sin(i / 30) * 0.2,
        0.5 + cos(i / 20) * 0.1,
      ),
    );
  });

  const iterations = 200;
  final watch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    MotionMetrics.compute(samples: samples, expectedAmplitude: 0.3);
  }
  watch.stop();

  final perRunUs = (watch.elapsedMicroseconds / iterations).round();
  print('Average processing time: ${perRunUs}μs per window');
  print('Target: <1000μs (1ms) for real-time 30 FPS');
  print('Status: ${perRunUs < 1000 ? "✓ PASS" : "✗ FAIL"}\n');
}

Future<void> _benchmarkModelInference() async {
  print('Benchmark 2: TFLite Model Inference Timing');
  print('---');
  print('Note: Placeholder benchmark - model inference would be measured here');
  print('Expected metrics:');
  print('  - Model load time: <500ms');
  print('  - Inference time per frame: <33ms (30 FPS target)');
  print('  - Memory usage: <50MB');
  print('Status: N/A (demo mode)\n');
}

