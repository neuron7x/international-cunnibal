#!/usr/bin/env python3
import pathlib
import sys

DOC_FILES = sorted(pathlib.Path(".").rglob("*.md"))


def _first_heading_line(lines: list[str]) -> str | None:
    idx = 0
    while idx < len(lines) and not lines[idx].strip():
        idx += 1
    if idx >= len(lines):
        return None
    if lines[idx].strip() == "---":
        idx += 1
        while idx < len(lines) and lines[idx].strip() != "---":
            idx += 1
        if idx < len(lines):
            idx += 1
    while idx < len(lines) and not lines[idx].strip():
        idx += 1
    if idx >= len(lines):
        return None
    return lines[idx]


def main() -> int:
    failures = []
    for doc in DOC_FILES:
        if not doc.exists():
            continue
        lines = doc.read_text(encoding="utf-8").splitlines()
        for idx, line in enumerate(lines, start=1):
            if line.rstrip() != line:
                failures.append(f"{doc}:{idx} has trailing whitespace.")
        first_heading = _first_heading_line(lines)
        if first_heading is None:
            continue
        if not first_heading.startswith("# "):
            failures.append(f"{doc} must start with a markdown '# ' heading.")

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
