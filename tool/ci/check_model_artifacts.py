#!/usr/bin/env python3
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
    failures = []

    tracked = git_ls_files()
    for path in tracked:
        if path.endswith(MODEL_EXTENSIONS):
            failures.append(f"Model binary tracked in git: {path}")

    changed = get_changed_files(base_ref)
    model_changed = any(path.startswith(MODEL_DIR) for path in changed)

    if model_changed:
        card_changed = any(path.startswith(MODEL_CARD_DIR) for path in changed)
        bench_changed = any(path.startswith(BENCH_DIR) for path in changed)
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
