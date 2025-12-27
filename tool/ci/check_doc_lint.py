#!/usr/bin/env python3
import pathlib
import sys

DOC_FILES = [
    pathlib.Path("ENGINEERING_HANDBOOK.md"),
    pathlib.Path("CONTRIBUTING.md"),
    pathlib.Path("ARCHITECTURE.md"),
]

DOC_FILES.extend(pathlib.Path("docs").glob("*.md"))


def main() -> int:
    failures = []
    for doc in DOC_FILES:
        if not doc.exists():
            continue
        lines = doc.read_text(encoding="utf-8").splitlines()
        for idx, line in enumerate(lines, start=1):
            if line.rstrip() != line:
                failures.append(f"{doc}:{idx} has trailing whitespace.")
        for line in lines:
            if line.strip():
                if not line.startswith("#"):
                    failures.append(f"{doc} must start with a markdown heading.")
                break

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
