# ML Ops

This directory is the single source of truth for model and dataset tracking.

## DVC Workflow
1. `dvc add ml-ops/models/<model-name>.tflite`
2. Commit the generated `.dvc` file.
3. Update the model card in `ml-ops/model_cards/`.
4. Add a benchmark log in `ml-ops/benchmarks/`.

## Rules
- No binary model files are committed to Git.
- Every model has a model card and benchmark log.
