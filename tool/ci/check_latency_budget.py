#!/usr/bin/env python3
import re
import subprocess
import sys

MAX_MICROS = 16000
SAMPLE_OUTPUT = "MEAN_US=1234"


def parse_mean_us(output: str) -> float | None:
    match = re.search(r"MEAN_US=([0-9]+)", output)
    if not match:
        return None
    return float(match.group(1))


def self_check() -> None:
    parsed = parse_mean_us(SAMPLE_OUTPUT)
    if parsed is None or parsed != 1234:
        raise RuntimeError("Latency parser self-check failed.")


def main() -> int:
    self_check()
    result = subprocess.run(
        ["flutter", "dart", "run", "tool/benchmark_core.dart"],
        check=True,
        capture_output=True,
        text=True,
    )
    output = result.stdout.strip()
    micros = parse_mean_us(output)
    if micros is None:
        print("ERROR: Unable to parse benchmark output.")
        print(output)
        return 1

    if micros > MAX_MICROS:
        print(f"ERROR: Benchmark exceeded latency budget: {micros}µs > {MAX_MICROS}µs")
        return 1

    print(f"Latency budget OK: {micros}µs <= {MAX_MICROS}µs")
    return 0


if __name__ == "__main__":
    sys.exit(main())
