#!/usr/bin/env python3
import fnmatch
import os
import subprocess
import sys

METRIC_PATHS = (
    "lib/core/",
    "lib/models/metrics.dart",
    "lib/services/neural_engine.dart",
    "lib/services/endurance_engine.dart",
    "lib/services/endurance_game_logic_service.dart",
)

TEST_PATHS = (
    "test/",
)

BENCHMARK_PATH = "ml-ops/benchmarks/"
METRICS_BENCHMARK_PATTERN = "metrics_benchmark_*.md"


def matches_benchmark_pattern(changed_files: list[str], pattern: str) -> bool:
    return any(
        fnmatch.fnmatch(path, f"{BENCHMARK_PATH}{pattern}")
        for path in changed_files
    )


def get_changed_files(base_ref: str) -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--name-only", f"{base_ref}...HEAD"],
        check=True,
        capture_output=True,
        text=True,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def main() -> int:
    base_ref = os.environ.get("BASE_REF", "origin/main")
    changed = get_changed_files(base_ref)

    metric_changed = any(path.startswith(METRIC_PATHS) or path in METRIC_PATHS for path in changed)
    if not metric_changed:
        return 0

    tests_changed = any(path.startswith(TEST_PATHS) for path in changed)
    bench_changed = matches_benchmark_pattern(changed, METRICS_BENCHMARK_PATTERN)

    failures = []
    if not tests_changed:
        failures.append("Metrics changed without updated tests.")
    if not bench_changed:
        failures.append("Metrics changed without benchmark log in ml-ops/benchmarks/.")

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
