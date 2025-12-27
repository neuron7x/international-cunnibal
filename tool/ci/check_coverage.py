#!/usr/bin/env python3
import pathlib
import sys

MIN_COVERAGE = 0.8
LCOV_FILE = pathlib.Path("coverage/lcov.info")


def main() -> int:
    if not LCOV_FILE.exists():
        print("ERROR: coverage/lcov.info not found.")
        return 1

    total_lines = 0
    covered_lines = 0
    for line in LCOV_FILE.read_text(encoding="utf-8").splitlines():
        if line.startswith("DA:"):
            _, data = line.split(":", 1)
            _, hits = data.split(",", 1)
            total_lines += 1
            if int(hits) > 0:
                covered_lines += 1

    if total_lines == 0:
        print("ERROR: No coverage data found.")
        return 1

    coverage = covered_lines / total_lines
    print(f"Coverage: {coverage:.2%} (min {MIN_COVERAGE:.0%})")
    if coverage < MIN_COVERAGE:
        print("ERROR: Coverage below threshold.")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
