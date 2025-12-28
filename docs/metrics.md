# Metrics & Domain Logic

## Ownership
Owned by the Metrics & Domain Logic RE (see CODEOWNERS).

## Guardrails
- Every metric change **must** ship with a unit test update and a benchmark log.
- Numeric outputs must be deterministic for the same inputs.
- Metrics are bounded to defined ranges:
  - Score-like outputs clamp to `0..100`.
  - Ratio/confidence outputs clamp to `0..1`.
  - Non-finite inputs or intermediate values are treated as safe zeros.
  - `enduranceTime` is always finite (non-finite durations become `0`).
- The full metric constitution lives in [`docs/METRICS.md`](METRICS.md).

## Regression Baselines
- `MotionMetrics` golden tests live in `test/motion_metrics_test.dart`.
- `EnduranceMetrics` baselines live in `test/endurance_metrics_test.dart`.
- Service integrations live in `lib/services/endurance_engine.dart` and
  `lib/services/endurance_game_logic_service.dart`.
- Benchmarks are logged in `ml-ops/benchmarks/` and referenced in PRs.

## Gate Hooks
- CI: `tool/ci/check_metric_changes.py` (tests required when metrics change).
- CI: `tool/ci/check_latency_budget.py` (16ms budget).
- Benchmark output is canonicalized as `MEAN_US=<int>` by `tool/benchmark_core.dart`.

## CI note (2025-12-28)
- Documented that recent PR changes only refined CI gates (doc/coverage/benchmark enforcement) without modifying metric formulas, clamps, or thresholds.
- Clarified why no normalization or scoring ranges were touched; focus was analyzer/test and governance noise reduction.
- Invariant impact: unchanged (0–100 scores and 0–1 ratios remain identical).
