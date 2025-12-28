# ML & CV Pipeline

## Ownership
Owned by the CV / ML Pipeline RE (see CODEOWNERS).

## Non-Negotiables
- Edge-first, on-device inference only.
- No raw video persistence; only landmarks/skeleton data leave the CV layer.
- Model assets are encrypted at rest and tracked via DVC.

## Service Entry Points
- CV orchestration and UI-facing adapters live in `lib/services/ui/`.
- Core CV services include `lib/services/ui/cv_engine.dart` and
  `lib/services/ui/bio_tracking_service.dart`.

## Model Asset Rules
- Binary model artifacts **must not** be committed to Git.
- Use DVC (`dvc add`) to track models and datasets.
- Every model requires:
  - Model card in `ml-ops/model_cards/`.
  - Benchmark log in `ml-ops/benchmarks/`.

## Validation Gates
- `tool/ci/check_model_artifacts.py` blocks raw binaries.
- `tool/ci/check_privacy_guards.py` blocks raw video persistence patterns.
- `tool/ci/check_latency_budget.py` enforces 16ms barrier.

## CI note (2025-12-28)
- Recorded that current PR only adjusts CI governance (doc/coverage/benchmark gating) without altering model interfaces, inference pipelines, or pre/post-processing.
- Noted rationale: reduce false positives in doc gate while leaving ML logic untouched.
- Invariant impact: unchanged (model loading and pipeline behavior remain the same).
