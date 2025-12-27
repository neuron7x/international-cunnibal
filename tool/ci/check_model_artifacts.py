#!/usr/bin/env python3
import fnmatch
import os
import subprocess
import sys

MODEL_EXTENSIONS = (
    ".onnx",
    ".pt",
    ".tflite",
    ".h5",
    ".ckpt",
    ".bin",
    ".mlmodel",
    ".mlpackage",
    ".model",
    ".weights",
    ".pb",
)

MODEL_DIR = "ml-ops/models/"
MODEL_CARD_DIR = "ml-ops/model_cards/"
BENCH_DIR = "ml-ops/benchmarks/"
MODEL_BENCHMARK_PATTERN = "model_benchmark_*.md"


def matches_benchmark_pattern(changed_files: list[str], pattern: str) -> bool:
    return any(
        fnmatch.fnmatch(path, f"{BENCH_DIR}{pattern}")
        for path in changed_files
    )


def git_ls_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files"],
        check=True,
        capture_output=True,
        text=True,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


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
    failures = []

    tracked = git_ls_files()
    for path in tracked:
        if path.endswith(MODEL_EXTENSIONS):
            failures.append(f"Model binary tracked in git: {path}")

    changed = get_changed_files(base_ref)
    model_changed = any(path.startswith(MODEL_DIR) for path in changed)

    if model_changed:
        card_changed = any(path.startswith(MODEL_CARD_DIR) for path in changed)
        bench_changed = matches_benchmark_pattern(changed, MODEL_BENCHMARK_PATTERN)
        if not card_changed:
            failures.append("Model change requires model card update in ml-ops/model_cards/.")
        if not bench_changed:
            failures.append("Model change requires benchmark log in ml-ops/benchmarks/.")

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
