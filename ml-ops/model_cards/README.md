# Model Cards

Each model requires a model card documenting:
- Name and version
- Training data provenance
- Accuracy metrics
- Size and latency
- Privacy considerations
- Evaluation date

Use the following template for new models.

```markdown
# Model Card: <model-name>

## Summary
- Version:
- Owner:
- Task:

## Data
- Dataset:
- Licensing:

## Metrics
- Accuracy:
- Latency (ms):
- Size (MB):

## Safety & Privacy
- Landmark-only processing:
- Encryption at rest:

## Evaluation
- Benchmark log: ml-ops/benchmarks/<log-file>
- Date:
```
