#!/usr/bin/env python3
import re
import subprocess
import sys

MAX_MICROS = 16000


def main() -> int:
    result = subprocess.run(
        ["flutter", "dart", "run", "tool/benchmark_core.dart"],
        check=True,
        capture_output=True,
        text=True,
    )
    output = result.stdout.strip()
    match = re.search(r"~([0-9.]+)µs per run", output)
    if not match:
        print("ERROR: Unable to parse benchmark output.")
        print(output)
        return 1

    micros = float(match.group(1))
    if micros > MAX_MICROS:
        print(f"ERROR: Benchmark exceeded latency budget: {micros}µs > {MAX_MICROS}µs")
        return 1

    print(f"Latency budget OK: {micros}µs <= {MAX_MICROS}µs")
    return 0


if __name__ == "__main__":
    sys.exit(main())
