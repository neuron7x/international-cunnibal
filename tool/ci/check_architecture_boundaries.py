#!/usr/bin/env python3
import pathlib
import sys

FORBIDDEN_DOMAIN_IMPORTS = (
    "package:flutter",
    "dart:ui",
    "package:camera",
    "package:international_cunnibal/screens",
    "package:international_cunnibal/widgets",
)

DOMAIN_DIRS = (
    pathlib.Path("lib/core"),
    pathlib.Path("lib/services"),
)
UI_SERVICE_DIR = pathlib.Path("lib/services/ui")


def scan_forbidden_imports(
    path: pathlib.Path,
    forbidden: tuple[str, ...],
    *,
    exclude: pathlib.Path | None = None,
) -> list[str]:
    failures = []
    for file in path.rglob("*.dart"):
        if exclude is not None and exclude in file.parents:
            continue
        contents = file.read_text(encoding="utf-8")
        for token in forbidden:
            if token in contents:
                failures.append(f"{file} imports forbidden dependency '{token}'.")
    return failures


def main() -> int:
    failures = []
    for domain_dir in DOMAIN_DIRS:
        if domain_dir.exists():
            failures.extend(
                scan_forbidden_imports(
                    domain_dir,
                    FORBIDDEN_DOMAIN_IMPORTS,
                    exclude=UI_SERVICE_DIR,
                )
            )

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
