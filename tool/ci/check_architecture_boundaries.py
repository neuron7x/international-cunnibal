#!/usr/bin/env python3
import pathlib
import sys

FORBIDDEN_IMPORTS = (
    "package:flutter",
    "dart:ui",
    "package:camera",
)

CORE_DIR = pathlib.Path("lib/core")
SERVICES_DIR = pathlib.Path("lib/services")

FORBIDDEN_SERVICE_IMPORTS = (
    "package:international_cunnibal/screens",
    "package:international_cunnibal/widgets",
)


def scan_forbidden_imports(path: pathlib.Path, forbidden: tuple[str, ...]) -> list[str]:
    failures = []
    for file in path.rglob("*.dart"):
        contents = file.read_text(encoding="utf-8")
        for token in forbidden:
            if token in contents:
                failures.append(f"{file} imports forbidden dependency '{token}'.")
    return failures


def main() -> int:
    failures = []
    if CORE_DIR.exists():
        failures.extend(scan_forbidden_imports(CORE_DIR, FORBIDDEN_IMPORTS))
    if SERVICES_DIR.exists():
        failures.extend(scan_forbidden_imports(SERVICES_DIR, FORBIDDEN_SERVICE_IMPORTS))

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
