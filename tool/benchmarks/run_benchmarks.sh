#!/usr/bin/env bash
set -euo pipefail

STAMP=$(date +"%Y%m%d_%H%M%S")
OUT_DIR="ml-ops/benchmarks"
OUT_FILE="$OUT_DIR/core_benchmark_${STAMP}.log"

mkdir -p "$OUT_DIR"

echo "Benchmark run at $(date -u)" > "$OUT_FILE"

dart run tool/benchmark_core.dart | tee -a "$OUT_FILE"

echo "Saved log to $OUT_FILE"
