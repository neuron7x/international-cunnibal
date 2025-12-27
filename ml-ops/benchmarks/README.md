# Benchmark Logs

Benchmark logs are required for any PR touching ML/CV or model assets.

## Standard Format
Use Markdown files with the naming pattern below and capture results in a
single table. This keeps CI enforcement consistent.

### File naming
- Metric changes: `metrics_benchmark_YYYYMMDD.md`
- Model changes: `model_benchmark_YYYYMMDD.md`

### Required fields
Each log **must** include the following columns:
- Date
- Change summary (metric or model change)
- Model/version
- Device or CI environment
- Latency (ms)
- FPS
- Memory (if available)

### Template
```markdown
# Metric Benchmark - YYYY-MM-DD

| Date | Change summary | Model/version | Device/CI | Latency (ms) | FPS | Memory (MB) | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| YYYY-MM-DD | <short summary> | <model/version> | <device/ci> | <latency> | <fps> | <memory> | <optional> |
```

Place logs under `ml-ops/benchmarks/` and reference them in the PR.
