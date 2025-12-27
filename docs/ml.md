# ML & CV Pipeline

## Ownership
Owned by the CV / ML Pipeline RE (see CODEOWNERS).

## Non-Negotiables
- Edge-first, on-device inference only.
- No raw video persistence; only landmarks/skeleton data leave the CV layer.
- Model assets are encrypted at rest and tracked via DVC.

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
