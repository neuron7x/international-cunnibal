#!/usr/bin/env python3
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Iterable

# Semantic domains
METRIC_FILES = {
    "lib/core/motion_metrics.dart",
    "lib/core/endurance_metrics.dart",
    "lib/models/metrics.dart",
    "lib/services/neural_engine.dart",
}

ML_FILES = {
    "lib/services/ui/cv_engine.dart",
    "lib/services/ui/bio_tracking_service.dart",
    "lib/models/tongue_data.dart",
}

ARCH_PREFIXES = (
    "lib/services/",
    "lib/services/ui/",
    "lib/core/",
)

DOC_METRICS = {"docs/metrics.md", "ENGINEERING_HANDBOOK.md"}
DOC_ML = {"docs/ml.md", "ENGINEERING_HANDBOOK.md"}
DOC_ARCH = {"docs/architecture.md", "ARCHITECTURE.md", "ENGINEERING_HANDBOOK.md"}

INVARIANT_KEYWORDS = {"invariant", "unchanged", "tightened", "expanded", "broadened", "narrowed"}


def run_git(args: list[str]) -> str:
    result = subprocess.run(args, check=True, capture_output=True, text=True)
    return result.stdout


def get_changed_files(base_ref: str) -> list[str]:
    return [
        line.strip()
        for line in run_git(["git", "diff", "--name-only", f"{base_ref}...HEAD"]).splitlines()
        if line.strip()
    ]


def load_diff(base_ref: str, path: str) -> list[str]:
    return run_git(["git", "diff", "-U0", f"{base_ref}...HEAD", "--", path]).splitlines()


def is_comment_or_whitespace(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return True
    return stripped.startswith(("//", "/*", "*", "///"))


def is_formatting_only(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return True
    # Braces, commas, semicolons, empty blocks
    if re.fullmatch(r"[{}();,\[\]]+", stripped):
        return True
    return False


def has_numeric_or_operator(line: str) -> bool:
    return bool(
        re.search(r"[0-9]", line)
        or any(op in line for op in ("+", "-", "*", "/", "%", ">=", "<=", "==", "!=", ">", "<", "="))
        or any(token in line for token in ("clamp", "threshold", "normalize", "score", "stability", "variance"))
    )


def is_signature_change(line: str) -> bool:
    stripped = line.strip()
    if stripped.startswith("import "):
        return False
    return "(" in stripped and ")" in stripped and not stripped.startswith("if ")


def semantic_metric_line(line: str) -> bool:
    return not is_comment_or_whitespace(line) and not is_formatting_only(line) and (
        has_numeric_or_operator(line) or "return" in line or is_signature_change(line)
    )


def semantic_ml_line(line: str) -> bool:
    return not is_comment_or_whitespace(line) and not is_formatting_only(line) and (
        "model" in line
        or "inference" in line
        or "preprocess" in line
        or "postprocess" in line
        or is_signature_change(line)
        or "CameraController" in line
    )


def semantic_arch_line(line: str) -> bool:
    stripped = line.strip()
    if is_comment_or_whitespace(stripped) or is_formatting_only(stripped):
        return False
    if stripped.startswith("import ") and (
        "services" in stripped or "core" in stripped or "ui" in stripped
    ):
        return True
    return is_signature_change(stripped)


def has_semantic_change(base_ref: str, path: str, classifier) -> bool:
    for diff_line in load_diff(base_ref, path):
        if not diff_line.startswith(("+", "-")) or diff_line.startswith(("+++", "---")):
            continue
        code = diff_line[1:]
        if classifier(code):
            return True
    return False


def doc_update_is_valid(base_ref: str, doc_path: str) -> bool:
    header = False
    bullet = False
    invariant = False
    for diff_line in load_diff(base_ref, doc_path):
        if not diff_line.startswith("+") or diff_line.startswith("+++"):
            continue
        line = diff_line[1:].strip()
        if line.startswith("#"):
            header = True
        if line.startswith(("-", "*")):
            bullet = True
        if any(keyword in line.lower() for keyword in INVARIANT_KEYWORDS):
            invariant = True
    return header and bullet and invariant


def doc_set_has_valid_update(base_ref: str, changed: Iterable[str], doc_set: set[str]) -> bool:
    for doc in changed:
        if doc in doc_set and doc_update_is_valid(base_ref, doc):
            return True
    return False


def main() -> int:
    base_ref = os.environ.get("BASE_REF", "origin/main")
    changed = get_changed_files(base_ref)

    failures: list[str] = []

    # Skip test-only changes
    non_test_changed = [p for p in changed if not p.startswith("test/")]

    # Metrics gate
    metric_files_changed = [p for p in non_test_changed if p in METRIC_FILES]
    metric_semantic = any(has_semantic_change(base_ref, p, semantic_metric_line) for p in metric_files_changed)
    if metric_semantic and not doc_set_has_valid_update(base_ref, changed, DOC_METRICS):
        failures.append(
            "METRICS_CHANGE detected; update docs/metrics.md or ENGINEERING_HANDBOOK.md with header, bullet, and invariant impact."
        )

    # ML/CV gate
    ml_files_changed = [p for p in non_test_changed if p in ML_FILES]
    ml_semantic = any(has_semantic_change(base_ref, p, semantic_ml_line) for p in ml_files_changed)
    if ml_semantic and not doc_set_has_valid_update(base_ref, changed, DOC_ML):
        failures.append(
            "ML_CV_CHANGE detected; update docs/ml.md or ENGINEERING_HANDBOOK.md with header, bullet, and invariant impact."
        )

    # Architecture gate
    arch_files_changed = [p for p in non_test_changed if p.startswith(ARCH_PREFIXES)]
    arch_semantic = any(has_semantic_change(base_ref, p, semantic_arch_line) for p in arch_files_changed)
    if arch_semantic and not doc_set_has_valid_update(base_ref, changed, DOC_ARCH):
        failures.append(
            "ARCHITECTURE_CHANGE detected; update docs/architecture.md or ARCHITECTURE.md (header, bullet, invariant impact)."
        )

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
