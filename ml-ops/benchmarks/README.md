# Benchmark Logs

Benchmark logs are required for any PR touching ML/CV or model assets.

## Format
Logs can be text or JSON but must include:
- Model/version
- Device or CI environment
- Latency (ms)
- FPS
- Memory (if available)
- Date

Place logs under `ml-ops/benchmarks/` and reference them in the PR.
