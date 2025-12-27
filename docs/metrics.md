# Metrics & Domain Logic

## Ownership
Owned by the Metrics & Domain Logic RE (see CODEOWNERS).

## Guardrails
- Every metric change **must** ship with a unit test update and a benchmark log.
- Numeric outputs must be deterministic for the same inputs.
- Metrics are bounded to defined ranges (e.g., 0-100 for scores).
- The full metric constitution lives in [`docs/METRICS.md`](METRICS.md).

## Performance Notes
- `MotionMetrics.compute` reuses cached signal statistics and sequential
  interpolation to reduce redundant passes.
- `EnduranceMetrics.compute` aggregates aperture statistics in a single pass
  and reuses cached summary stats for stability/fatigue.
- `NeuralEngine` caches PCA sums for O(1) variance updates.

## Regression Baselines
- `MotionMetrics` golden tests live in `test/motion_metrics_test.dart`.
- Benchmarks are logged in `ml-ops/benchmarks/` and referenced in PRs.

## Gate Hooks
- CI: `tool/ci/check_metric_changes.py` (tests required when metrics change).
- CI: `tool/ci/check_latency_budget.py` (16ms budget).
