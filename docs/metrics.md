# Metrics & Domain Logic

## Ownership
Owned by the Metrics & Domain Logic RE (see CODEOWNERS).

## Guardrails
- Every metric change **must** ship with a unit test update and a benchmark log.
- Numeric outputs must be deterministic for the same inputs.
- Metrics are bounded to defined ranges (e.g., 0-100 for scores).

## Regression Baselines
- `MotionMetrics` golden tests live in `test/motion_metrics_test.dart`.
- Benchmarks are logged in `ml-ops/benchmarks/` and referenced in PRs.

## Gate Hooks
- CI: `tool/ci/check_metric_changes.py` (tests required when metrics change).
- CI: `tool/ci/check_latency_budget.py` (16ms budget).
