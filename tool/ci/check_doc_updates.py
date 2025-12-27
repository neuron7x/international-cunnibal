#!/usr/bin/env python3
import os
import subprocess
import sys

METRIC_PATHS = (
    "lib/core/",
    "lib/models/metrics.dart",
    "lib/services/neural_engine.dart",
)

ML_PATHS = (
    "lib/services/cv_engine.dart",
    "lib/services/bio_tracking_service.dart",
    "lib/models/tongue_data.dart",
    "ml-ops/",
)

ARCH_PATHS = (
    "lib/services/",
    "lib/utils/",
    "lib/core/",
    "lib/models/",
)

DOC_METRICS = {"docs/metrics.md", "ENGINEERING_HANDBOOK.md"}
DOC_ML = {"docs/ml.md", "ENGINEERING_HANDBOOK.md"}
DOC_ARCH = {"docs/architecture.md", "ARCHITECTURE.md", "ENGINEERING_HANDBOOK.md"}


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


def any_matches(changed: list[str], prefixes: tuple[str, ...]) -> bool:
    return any(path.startswith(prefixes) or path in prefixes for path in changed)


def any_docs_changed(changed: list[str], docs: set[str]) -> bool:
    return any(path in docs or path.startswith("docs/") and path in docs for path in changed)


def main() -> int:
    base_ref = os.environ.get("BASE_REF", "origin/main")
    if not git_ref_exists(base_ref):
        base_ref = "HEAD~1"
        if not git_revision_exists(base_ref):
            base_ref = "HEAD"
    changed = get_changed_files(base_ref)

    failures = []

    if any_matches(changed, METRIC_PATHS) and not any(path in DOC_METRICS for path in changed):
        failures.append("Metrics changes require docs/metrics.md or ENGINEERING_HANDBOOK.md updates.")

    if any_matches(changed, ML_PATHS) and not any(path in DOC_ML for path in changed):
        failures.append("ML/CV changes require docs/ml.md or ENGINEERING_HANDBOOK.md updates.")

    if any_matches(changed, ARCH_PATHS) and not any(path in DOC_ARCH for path in changed):
        failures.append("Architecture changes require docs/architecture.md or ARCHITECTURE.md updates.")

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
