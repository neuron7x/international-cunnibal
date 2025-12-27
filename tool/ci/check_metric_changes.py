#!/usr/bin/env python3
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


def get_changed_files(base_ref: str) -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--name-only", f"{base_ref}...HEAD"],
        check=True,
        capture_output=True,
        text=True,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def git_ref_exists(ref: str) -> bool:
    candidates = [ref]
    if not ref.startswith("refs/"):
        candidates.append(f"refs/remotes/{ref}")
        candidates.append(f"refs/heads/{ref}")
    for candidate in candidates:
        result = subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", candidate],
            check=False,
        )
        if result.returncode == 0:
            return True
    return False


def git_revision_exists(revision: str) -> bool:
    result = subprocess.run(
        ["git", "rev-parse", "--verify", "--quiet", revision],
        check=False,
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def main() -> int:
    base_ref = os.environ.get("BASE_REF", "origin/main")
    if not git_ref_exists(base_ref):
        base_ref = "HEAD~1"
        if not git_revision_exists(base_ref):
            base_ref = "HEAD"
    changed = get_changed_files(base_ref)

    metric_changed = any(path.startswith(METRIC_PATHS) or path in METRIC_PATHS for path in changed)
    if not metric_changed:
        return 0

    tests_changed = any(path.startswith(TEST_PATHS) for path in changed)
    bench_changed = any(path.startswith(BENCHMARK_PATH) for path in changed)

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
